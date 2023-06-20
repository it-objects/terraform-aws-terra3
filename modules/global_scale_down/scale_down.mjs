import { ECSClient, UpdateServiceCommand, ListServicesCommand, DescribeServicesCommand } from "@aws-sdk/client-ecs";
import { SSMClient, PutParameterCommand, GetParameterCommand} from "@aws-sdk/client-ssm";
import { RDSClient, StopDBInstanceCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, DeleteCacheClusterCommand } from "@aws-sdk/client-elasticache";

export const handler = async(event) => {
 try {
  const parameterStorePath = process.env.scale_up_parameters;

  // Retrieve stored parameter value from SSM Parameter Store
  const getParameterCommand = new GetParameterCommand({
    Name: parameterStorePath,
  });
  const ssmClient = new SSMClient();
  const getParameterResponse = await ssmClient.send(getParameterCommand);

    if (!getParameterResponse.Parameter) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'No stored parameter found' }),
      };
    }
  const storedData = JSON.parse(getParameterResponse.Parameter.Value);

  for (let i = 0; i < storedData.asg_name.length; i++){
      const ecs_ec2_asg_input = {
        "AutoScalingGroupName": storedData.asg_name[i],
        "MaxSize": 0,
        "MinSize": 0,
        "DesiredCapacity": 0,
      };
      const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(ecs_ec2_asg_input);
      const ecs_ec2_asg_client = new AutoScalingClient();
      await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
      console.log(`Auto scaling groups "${storedData.asg_name[i]}" updated successfully to 0.`);
  }
    // storedData.db_instance_name.length
  for (let i = 0; i < storedData.db_instance_name.length; i++){
      const db_input = {
        "DBInstanceIdentifier": storedData.db_instance_name[i],
      };
      const db_command = new StopDBInstanceCommand(db_input);
      const db_client = new RDSClient();
      await db_client.send(db_command);
      console.log(`DB instance "${storedData.db_instance_name[i]}" stopped successfully.`);
  }

    // storedData.redis_cluster_id.length
  for (let i = 0; i < storedData.redis_cluster_id.length; i++){
      const redis_memory_db = {
        "CacheClusterId": storedData.redis_cluster_id[i],
      };
      const redis_memory_db_command = new DeleteCacheClusterCommand(redis_memory_db);
      const redis_memory_db_client = new ElastiCacheClient();
      await redis_memory_db_client.send(redis_memory_db_command);
      console.log(`Redis cluster "${storedData.redis_cluster_id[i]}" stopped successfully.`);
  }

    const clusterName = storedData.cluster_name[0];
    // Call the listServices command to retrieve the list of ECS services
    const listServicesParams = {
      cluster: clusterName,
    };
    const listServicesCommand = new ListServicesCommand(listServicesParams);
    const ecsClient = new ECSClient();
    const listServicesResponse = await ecsClient.send(listServicesCommand);
    // Extract the service ARNs from the response
    const serviceArns = listServicesResponse.serviceArns;

    // Call the describeServices command to retrieve the list of running services
    const describeServicesParams = {
      cluster: clusterName,
      services: serviceArns,
    };
    const describeServicesCommand = new DescribeServicesCommand(describeServicesParams);
    const describeServicesResponse = await ecsClient.send(describeServicesCommand);
    // Extract the service names and desired counts from the response
    const servicesData = describeServicesResponse.services.map(service => ({
      name: service.serviceName,
      desiredCount: service.desiredCount
    }));

    // Store the service names in SSM Parameter Store
    const putParameterParams = {
      Name: process.env.ecs_service_data, // Set the desired path for the parameter
      Value: JSON.stringify(servicesData), // Store the service names as a comma-separated string
      Type: 'String',
      Overwrite: true,
    };
    const putParameterCommand = new PutParameterCommand(putParameterParams);
    const ssmClientPut = new SSMClient();
    await ssmClientPut.send(putParameterCommand);

   // Update the ECS service for each service in the stored data
    for (const serviceData of servicesData) {
      const updateServiceParams = {
        cluster: clusterName, // Specify the ECS cluster name
        service: serviceData.name, // Specify the ECS service name
        desiredCount: 0, // Set the desired count for the service
      };
      const updateServiceCommand = new UpdateServiceCommand(updateServiceParams);
      await ecsClient.send(updateServiceCommand);
      console.log(`Desired count of "${serviceData.name}"  set successfully to 0.`);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Successfully updated Global scale down' }),
    };
  } catch (error) {
    console.error('Error updating Global scale down:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to update Global scale down' }),
    };
  }
};
