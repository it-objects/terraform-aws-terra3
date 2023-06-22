import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { SSMClient, PutParameterCommand, GetParameterCommand} from "@aws-sdk/client-ssm";
import { RDSClient, StartDBInstanceCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, CreateCacheClusterCommand } from "@aws-sdk/client-elasticache";

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export const checkParameterValue = async(parameterName) => {
  const getParameterCommand = new GetParameterCommand({ Name: parameterName });

  try {
    const ssmClient = new SSMClient();
    const response = await ssmClient.send(getParameterCommand);
    const parameterValue = response.Parameter.Value;

    if (parameterValue === 'scaled_down') {
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error retrieving SSM parameter:', error);
      throw error;
    }
};

export const scale_up_handler = async(event) => {
try {
  const parameterStorePath = process.env.scale_up_parameters;

  // Retrieve stored parameter value from SSM Parameter Store
  const getParameterCommand = new GetParameterCommand({
    Name: parameterStorePath,
  });
  const ssmClient = new SSMClient();
  const getParameterResponse = await ssmClient.send(getParameterCommand);
  const storedData = JSON.parse(getParameterResponse.Parameter.Value);

  for (let i = 0; i < storedData.asg_name.length; i++){
    const ecs_ec2_asg_input = {
      "AutoScalingGroupName": storedData.asg_name[i],
      "MaxSize": storedData.asg_max_capacity[i],
      "MinSize": storedData.asg_min_capacity[i],
      "DesiredCapacity": storedData.asg_desired_capacity[i],
    };
    const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(ecs_ec2_asg_input);
    const ecs_ec2_asg_client = new AutoScalingClient();
    await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
    console.log(`Auto scaling groups "${storedData.asg_name[i]}" updated successfully to ${storedData.asg_desired_capacity[i]}.`);
  }

  for (let i = 0; i < storedData.db_instance_name.length; i++){
    const db_input = {
      "DBInstanceIdentifier": storedData.db_instance_name[i],
    };
    const db_command = new StartDBInstanceCommand(db_input);
    const db_client = new RDSClient();
    await db_client.send(db_command);
    console.log(`DB instance ${storedData.db_instance_name[i]} started successfully.`);
  }

  const clusterName = storedData.cluster_name[0];
  // Retrieve the stored service data from SSM Parameter Store
  const getParameterParams = {
    Name: process.env.ecs_service_data, // Set the path of the stored parameter
    };
  const getECSParameterCommand = new GetParameterCommand(getParameterParams);
  const ssmClientPUT = new SSMClient();
  const getECSParameterResponse = await ssmClientPUT.send(getECSParameterCommand);

  // Use the retrieved parameter value for further processing, if needed
  let storedServicesData = [];
  if (getECSParameterResponse.Parameter) {
    const storedParameter = JSON.parse(getECSParameterResponse.Parameter.Value);
     if (Array.isArray(storedParameter)) {
        // Check if the stored parameter has the correct structure
        const isValidParameter = storedParameter.every(item => item.name && item.desiredCount);
        if (isValidParameter) {
          storedServicesData = storedParameter;
        }
      }
  }

  // Update the ECS service using the stored parameter data again
  for (const serviceData of storedServicesData) {
    const updateServiceParams = {
      cluster: clusterName, // Specify the ECS cluster name
      service: serviceData.name, // Specify the ECS service name
      desiredCount: serviceData.desiredCount, // Set the desired count for the service
    };
    const updateServiceCommand = new UpdateServiceCommand(updateServiceParams);
    const ecsClient = new ECSClient();
    await ecsClient.send(updateServiceCommand);
    console.log(`Desired count of "${serviceData.name}"  set successfully to ${serviceData.desiredCount}.`);
  }

  for (let i = 0; i < storedData.redis_cluster_id.length; i++){
    const redis_memory_db = {
      CacheClusterId: storedData.redis_cluster_id[i],
      NumCacheNodes: storedData.redis_num_cache_nodes,
      CacheNodeType: storedData.redis_node_type[i],
      Engine: storedData.redis_engine[i],
      EngineVersion: storedData.redis_engine_version[i],
      CacheSubnetGroupName: storedData.redis_subnet_group_name[i],
      SecurityGroupIds: storedData.redis_security_group_ids[i],
    };
    const redis_memory_db_command = new CreateCacheClusterCommand(redis_memory_db);
    const redis_memory_db_client = new ElastiCacheClient({ region: "eu-central-1" });
    await redis_memory_db_client.send(redis_memory_db_command);
    console.log(`Redis cluster "${storedData.redis_cluster_id[i]}" started successfully.`);
  }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Successfully updated Global scale up' }),
    };
  } catch (error) {
    console.error('Error updating Global scale up:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to update Global scale up' }),
    };
  }
};



export const updateParameterValue = async(parameterName, parameterValue) => {
  console.log("Waiting for 8 minutes");
  await pause(480000); // Pause for 8 minutes

  const putParameterCommand = new PutParameterCommand({
    Name: parameterName,
    Value: parameterValue,
    Type: 'String',
    Overwrite: true,
  });

  try {
    const ssmClientPUT = new SSMClient();
    await ssmClientPUT.send(putParameterCommand);
    console.log('SSM parameter value updated successfully.');
  } catch (error) {
    console.error('Error updating SSM parameter:', error);
    throw error;
  }
};

export const handler = async(event) => {
  const parameterName = '/g-scale-down/global_scale_down/hibernation_state';
try {
    const isValueValid = await checkParameterValue(parameterName);

    if (isValueValid) {
      console.log('The stored value is valid. Continuing with Lambda execution...');
      await scale_up_handler();
      await updateParameterValue(parameterName, 'scaled_up');
      console.log('Hibernation state has been successfully changed to scaled up.');
      // Add your Lambda function code here
    } else {
      console.log('The stored value is not valid. Stopping Lambda execution...');
      return; // Stop Lambda execution
    }
  } catch (error) {
    console.error('Error:', error);
  }
};
