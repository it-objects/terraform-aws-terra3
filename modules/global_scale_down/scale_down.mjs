import { ECSClient, UpdateServiceCommand, ListServicesCommand, DescribeServicesCommand } from "@aws-sdk/client-ecs";
import { SSMClient, PutParameterCommand} from "@aws-sdk/client-ssm";
import { RDSClient, StopDBInstanceCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, DeleteCacheClusterCommand } from "@aws-sdk/client-elasticache";

export const handler = async(event) => {

    for (let i = 0; i < event.ecs_ec2_instances_asg_names.length; i++){
        const ecs_ec2_asg_input = {
          "AutoScalingGroupName": event.ecs_ec2_instances_asg_names[i],
          "MaxSize": 0,
          "MinSize": 0,
          "DesiredCapacity": 0,
        };
        const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(ecs_ec2_asg_input);
        const ecs_ec2_asg_client = new AutoScalingClient();
        await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
    }

    for (let i = 0; i < event.nat_instances_asg_names.length; i++){
        const nat_asg_input = {
          "AutoScalingGroupName": event.nat_instances_asg_names[i],
          "MaxSize": 0,
          "MinSize": 0,
          "DesiredCapacity": 0,
        };
        const nat_asg_command = new UpdateAutoScalingGroupCommand(nat_asg_input);
        const nat_asg_client = new AutoScalingClient();
        await nat_asg_client.send(nat_asg_command);
    }

    for (let i = 0; i < event.bastion_host_asg_name.length; i++){
        const bastion_host_asg_input = {
          "AutoScalingGroupName": event.bastion_host_asg_name[i],
          "MaxSize": 0,
          "MinSize": 0,
          "DesiredCapacity": 0,
        };
        const bastion_host_asg_command = new UpdateAutoScalingGroupCommand(bastion_host_asg_input);
        const bastion_host_asg_client = new AutoScalingClient();
        await bastion_host_asg_client.send(bastion_host_asg_command);
    }

    for (let i = 0; i < event.db_instance_name.length; i++){
        const db_input = {
          "DBInstanceIdentifier": event.db_instance_name[i],
        };
        const db_command = new StopDBInstanceCommand(db_input);
        const db_client = new RDSClient();
        await db_client.send(db_command);
    }

    for (let i = 0; i < event.redis_cluster_id.length; i++){
        const redis_memory_db = {
          CacheClusterId: event.redis_cluster_id[i],
        };
        const redis_memory_db_command = new DeleteCacheClusterCommand(redis_memory_db);
        const redis_memory_db_client = new ElastiCacheClient();
        await redis_memory_db_client.send(redis_memory_db_command);
    }

    const clusterName = event.cluster_name[0];

      try {

        // Call the listServices command to retrieve the list of ECS services
        const listServicesParams = {
          cluster: clusterName,
        };
        const listServicesCommand = new ListServicesCommand(listServicesParams);
        const ecsClient = new ECSClient();
        const listServicesResponse = await ecsClient.send(listServicesCommand);
        // Extract the service ARNs from the response
        const serviceArns = listServicesResponse.serviceArns;
        console.log(serviceArns);


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
        // Log the service names
        console.log('Running services:');
        console.log(servicesData);


        // Store the service names in SSM Parameter Store
        const putParameterParams = {
          Name: '/ecs_service_data', // Set the desired path for the parameter
          Value: JSON.stringify(servicesData), // Store the service names as a comma-separated string
          Type: 'String',
          Overwrite: true,
        };
        const putParameterCommand = new PutParameterCommand(putParameterParams);
        const ssmClient = new SSMClient();
        await ssmClient.send(putParameterCommand);


       // Update the ECS service for each service in the stored data
        for (const serviceData of servicesData) {
          const updateServiceParams = {
            cluster: clusterName, // Specify the ECS cluster name
            service: serviceData.name, // Specify the ECS service name
            desiredCount: 0, // Set the desired count for the service
          };
          const updateServiceCommand = new UpdateServiceCommand(updateServiceParams);
          await ecsClient.send(updateServiceCommand);
        }

    return {
      statusCode: 200,
      body: JSON.stringify(servicesData),
    };
      } catch (error) {
        console.error('Error retrieving services:', error);

        return {
          statusCode: 500,
          body: JSON.stringify({ error: 'Failed to retrieve services' }),
        };
      }
};
