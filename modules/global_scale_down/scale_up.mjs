import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { SSMClient, PutParameterCommand, GetParameterCommand } from "@aws-sdk/client-ssm";
import { RDSClient, StartDBInstanceCommand, DescribeDBInstancesCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, CreateCacheClusterCommand, DescribeCacheClustersCommand } from "@aws-sdk/client-elasticache";

function timeout(ms) {
    return new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Operation timed out')), ms);
    });
}

export const handler = async (event, context) => {
  const parameterName = process.env.hibernation_state;
  const isAuthenticated = await handleAuthentication(event, context);
    const timer = setTimeout(async () => {
    console.log(`Remaining time for lambda execution before timeout: ${context.getRemainingTimeInMillis()} ms`);
      await updateParameterValue(parameterName, "lambda_timeout");
      console.log(`Updating parameter`);
    }, context.getRemainingTimeInMillis() - 1000);
    console.log(`Remaining time for lambda execution before timeout: ${context.getRemainingTimeInMillis()} ms`);
  try {
    if (isAuthenticated === true) {
      const isValueValid = await checkParameterValue(parameterName);
      if (isValueValid) {
        console.log(
          "The stored value is valid. Continuing with Lambda execution...",
        );
        // Use Promise.race to apply a timeout to the main operation
        const remainedTime = context.getRemainingTimeInMillis() - 500; //15 * 60 * 1000; // 15 minutes in milliseconds
        await Promise.race([
            mainOperation(parameterName, context, remainedTime),
            timeout(remainedTime),
        ]);
        return successResponse(
          "Hibernation state has been successfully changed to scaled up.",
        );
      } else {
        const parameterValue = await fetchParameterValue(parameterName);
        console.log('Fetched Parameter Value:', parameterValue);

        console.log('Stopping Lambda execution. The stored value is', parameterValue);
        return {
          statusCode: 400,
          body: JSON.stringify({
            error: `The environment is ${parameterValue}.`
            }),
        }}
    } else {
      return errorResponse("Entered token value is incorrect.", 401);
    }
  } catch (error) {
    console.error("Error during Lambda execution:", error);

    // Check if the error is not a timeout error before updating the parameter value
    if (error.message !== 'Operation timed out') {
        await updateParameterValue(parameterName, "error_stage");
    }
    //await updateParameterValue(parameterName, "error_stage");
    clearTimeout(timer);
    //return errorResponse(error.message);
    console.error('Error:', error.message);
    return {
        statusCode: error.message === 'Timeout exceeded' ? 408 : 500,
        body: JSON.stringify({ error: error.message }),
    };
  }
};

async function mainOperation(parameterName, context) {
    await updateParameterValue(parameterName, "scaling_up");
    await scaleUpResources();
    console.log("Scaling up on resources has been performed.");
    await waitForInstanceStatus("available", "available");
    await updateParameterValue(parameterName, "scaled_up");
    console.log("Hibernation state has been successfully changed to scaled up.");
}

export const handleAuthentication = async (event) => {
  console.log("checking the token:- ");
  const userProvidedToken = event?.queryStringParameters?.token;
  const EventBridgeToken = event.api_token;
  const tokenPath = process.env.admin_secret_credentials;

  const getParameterCommand = new GetParameterCommand({
    Name: tokenPath,
    WithDecryption: true,
  });
  try {
    const ssmClient = new SSMClient();
    const response = await ssmClient.send(getParameterCommand);

    // Parse the JSON data from the response
    const jsonData = JSON.parse(response.Parameter.Value);
    const userToken = jsonData.user_token;
    const apiToken = jsonData.api_token;

    if (userProvidedToken === userToken) {
      console.log('User provided token was used.');
      return true;
    } else if (EventBridgeToken === apiToken) {
      console.log('API token used.');
      return true;
    } else {
      return false;
    }
  } catch (error) {
    console.error("Error retrieving SSM parameter:", error);
    return {
      statusCode: 500,
      body: "Error",
    };
  }
};

export const checkParameterValue = async (parameterName) => {
  console.log("Currently checking the hibernation state");
  const getParameterCommand = new GetParameterCommand({
    Name: parameterName,
  });

  try {
    const ssmClient = new SSMClient();
    const response = await ssmClient.send(getParameterCommand);
    const parameterValue = response.Parameter.Value;
    if (parameterValue === "error_stage" || parameterValue === "scaled_down" || parameterValue === "lambda_timeout") {
      return true;
    }
    return false;
  } catch (error) {
    console.error("Error retrieving SSM parameter:", error);
    throw error;
  }
};

export const scaleUpResources = async (event) => {
  console.log("scaling up the deployment:");
  try {
    const parameterStorePath = process.env.scale_up_parameters;

    // Retrieve stored parameter value from SSM Parameter Store
    const getParameterCommand = new GetParameterCommand({
      Name: parameterStorePath,
    });
    const ssmClient = new SSMClient();
    const getParameterResponse = await ssmClient.send(getParameterCommand);
    const storedData = JSON.parse(getParameterResponse.Parameter.Value);

    await scaleUpAutoScalingGroups(storedData);
    await startEcsTasks(storedData);
    await startDBInstances(storedData);
    await createRedisClusters(storedData);

    // Add other resource scaling down functions as needed
  } catch (error) {
    throw new Error(`Error in scaleUpResources: ${error.message}`);
  }
};

export const scaleUpAutoScalingGroups = async (storedData) => {
  try {
    for (let i = 0; i < storedData.asg_name.length; i++) {
      const ecs_ec2_asg_input = {
        AutoScalingGroupName: storedData.asg_name[i],
        MaxSize: storedData.asg_max_capacity[i],
        MinSize: storedData.asg_min_capacity[i],
        DesiredCapacity: storedData.asg_desired_capacity[i],
      };
      const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(
        ecs_ec2_asg_input,
      );
      const ecs_ec2_asg_client = new AutoScalingClient();
      await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
      console.log(
        `Auto scaling groups "${storedData.asg_name[i]}" updated successfully to ${storedData.asg_desired_capacity[i]}.`,
      );
    }
  } catch (error) {
    throw new Error(`Error scaling up auto-scaling groups: ${error.message}`);
  }
};

export const startEcsTasks = async (storedData) => {
  try {
    const clusterName = storedData.cluster_name[0];
    // Retrieve the stored service data from SSM Parameter Store
    const getParameterParams = {
      Name: process.env.ecs_service_data, // Set the path of the stored parameter
    };
    const getECSParameterCommand = new GetParameterCommand(getParameterParams);
    const ssmClientPUT = new SSMClient();
    const getECSParameterResponse = await ssmClientPUT.send(
      getECSParameterCommand,
    );

    // Use the retrieved parameter value for further processing, if needed
    let storedServicesData = [];
    if (getECSParameterResponse.Parameter) {
      const storedParameter = JSON.parse(
        getECSParameterResponse.Parameter.Value,
      );
      if (Array.isArray(storedParameter)) {
        // Check if the stored parameter has the correct structure
        const isValidParameter = storedParameter.every(
          (item) => item.name && item.desiredCount,
        );
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
      const updateServiceCommand = new UpdateServiceCommand(
        updateServiceParams,
      );
      const ecsClient = new ECSClient();
      await ecsClient.send(updateServiceCommand);
      console.log(
        `Desired count of "${serviceData.name}"  set successfully to ${serviceData.desiredCount}.`,
      );
    }
  } catch (error) {
    throw new Error(`Error scaling up ECS services : ${error.message}`);
  }
};

export const startDBInstances = async (storedData) => {
  try {
    for (let i = 0; i < storedData.db_instance_name.length; i++) {
      const db_input = {
        DBInstanceIdentifier: storedData.db_instance_name[i],
      };
      const db_command = new StartDBInstanceCommand(db_input);
      const db_client = new RDSClient();
      await db_client.send(db_command);
      console.log(
        `DB instance ${storedData.db_instance_name[i]} started successfully.`,
      );
    }
  } catch (error) {
    throw new Error(
      `Error scaling down DB instance "${storedData.db_instance_name[0]}": ${error.message}`,
    );
  }
};

export const createRedisClusters = async (storedData) => {
  try {
    for (let i = 0; i < storedData.redis_cluster_id.length; i++) {
      const redis_memory_db = {
        CacheClusterId: storedData.redis_cluster_id[i],
        NumCacheNodes: storedData.redis_num_cache_nodes,
        CacheNodeType: storedData.redis_node_type[i],
        Engine: storedData.redis_engine[i],
        EngineVersion: storedData.redis_engine_version[i],
        CacheSubnetGroupName: storedData.redis_subnet_group_name[i],
        SecurityGroupIds: storedData.redis_security_group_ids[i],
      };
      const redis_memory_db_command = new CreateCacheClusterCommand(
        redis_memory_db,
      );
      const redis_memory_db_client = new ElastiCacheClient({
        region: "eu-central-1",
      });
      await redis_memory_db_client.send(redis_memory_db_command);
      console.log(
        `Redis cluster "${storedData.redis_cluster_id[i]}" started successfully.`,
      );
    }
  } catch (error) {
    throw new Error(
      `Error scaling up Redis cluster "${storedData.redis_cluster_id[0]}": ${error.message}`,
    );
  }
};

export const waitForInstanceStatus = async (
  desiredStatus,
  redisdesiredStatus,
) => {
  try {
    console.log("Waiting for the update to be done:");
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
        body: JSON.stringify({
          error: "No stored parameter found",
        }),
      };
    }
    const storedData = JSON.parse(getParameterResponse.Parameter.Value);

    await waitForDBInstanceStatus(storedData, desiredStatus);
    await waitForRedisInstanceStatus(storedData, redisdesiredStatus);
  } catch (error) {
    throw new Error(
      `Error waiting for DB/redis cluster creating status: ${error.message}`,
    );
  }
};

export const waitForDBInstanceStatus = async (storedData, desiredStatus) => {
  try {
    for (let i = 0; i < storedData.db_instance_name.length; i++) {
      const rdsClient = new RDSClient();
      const describeCommand = new DescribeDBInstancesCommand({
        DBInstanceIdentifier: storedData.db_instance_name[i],
      });

      while (true) {
        const response = await rdsClient.send(describeCommand);
        const dbInstances = response.DBInstances;

        if (dbInstances.length === 0) {
          throw new Error(
            `DB instance ${storedData.db_instance_name[i]} not found.`,
          );
        }

        const dbInstance = dbInstances[0];
        const currentStatus = dbInstance.DBInstanceStatus;

        console.log(
          `Current status of DB instance ${storedData.db_instance_name[i]}: ${currentStatus}`,
        );

        if (currentStatus === desiredStatus) {
          console.log(
            `DB instance ${storedData.db_instance_name[i]} is in the "${desiredStatus}" state.`,
          );
          break;
        }

        // Wait for 5 seconds before checking the status again
        await new Promise((resolve) => setTimeout(resolve, 5000));
      }
    }
  } catch (error) {
    throw new Error(`Error waiting for DB instance status: ${error.message}`);
  }
};

export const waitForRedisInstanceStatus = async (
  storedData,
  redisdesiredStatus,
) => {
  try {
    for (let i = 0; i < storedData.redis_cluster_id.length; i++) {
      console.log("Checking the redis cluster state");
      const redisClient = new ElastiCacheClient();
      const describeCommand = new DescribeCacheClustersCommand({
        CacheClusterId: storedData.redis_cluster_id[0],
      });

      while (true) {
        const response = await redisClient.send(describeCommand);
        const clusters = response.CacheClusters;

        const cluster = clusters[0];
        const currentStatus = cluster.CacheClusterStatus;

        console.log(
          `Current status of redis cluster ${storedData.redis_cluster_id[0]}: ${currentStatus}`,
        );

        if (currentStatus === redisdesiredStatus) {
          console.log(
            `Redis cluster ${storedData.redis_cluster_id[i]} is in the "${redisdesiredStatus}" state.`,
          );
          break;
        }

        // Wait for 5 seconds before checking the status again
        await new Promise((resolve) => setTimeout(resolve, 5000));
      }
    }
  } catch (error) {
    throw new Error(
      `Error waiting for Redis instance status: ${error.message}`,
    );
  }
};

export const updateParameterValue = async (parameterName, parameterValue) => {
  console.log("updating ssm parameter after updating the resources......");

  const putParameterCommand = new PutParameterCommand({
    Name: parameterName,
    Value: parameterValue,
    Type: "String",
    Overwrite: true,
  });

  try {
    const ssmClientPUT = new SSMClient();
    await ssmClientPUT.send(putParameterCommand);
    console.log(`SSM parameter value updated successfully to "${parameterValue}"`);
  } catch (error) {
    console.error("Error updating SSM parameter:", error);
    throw error;
  }
};

export const fetchParameterValue = async (parameterName, parameterValue) => {
  console.log("fetching ssm parameter......");

  const params = new GetParameterCommand({
    Name: parameterName,
    WithDecryption: true // Assuming the parameter might be encrypted
  });

  try {
    const ssmClient = new SSMClient();
    const response = await ssmClient.send(params);
    return response.Parameter.Value; // Return the fetched parameter value
    } catch (error) {
      console.error('Error fetching parameter:', error);
      throw error; // Rethrow the error to handle it in the main handler
    }
};

const errorResponse = (message, statusCode = 500) => ({
  statusCode,
  body: JSON.stringify({ Error: message }),
});

const successResponse = (message) => ({
  statusCode: 200,
  body: JSON.stringify({ Message: message }),
});
