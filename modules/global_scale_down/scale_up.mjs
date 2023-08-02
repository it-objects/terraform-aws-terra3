import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { SSMClient, PutParameterCommand, GetParameterCommand } from "@aws-sdk/client-ssm";
import { RDSClient, StartDBInstanceCommand, DescribeDBInstancesCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, CreateCacheClusterCommand, DescribeCacheClustersCommand } from "@aws-sdk/client-elasticache";

export const handler = async (event) => {
  const parameterName = process.env.hibernation_state;
  await handleAuthentication(event);
  const isAuthenticated = await handleAuthentication(event);
  try {
    if (isAuthenticated === true) {
      const isValueValid = await checkParameterValue(parameterName);
      if (isValueValid) {
        console.log(
          "The stored value is valid. Continuing with Lambda execution...",
        );

        await scale_up_handler();
        console.log("Scaling up on resources has been performed.");

        await waitForInstanceStatus("available", "available");

        await updateParameterValue(parameterName, "scaled_up");
        console.log(
          "Hibernation state has been successfully changed to scaled up.",
        );
        return {
          statusCode: 200,
          body: JSON.stringify({
            Log: "Hibernation state has been successfully changed to scaled up.",
          }),
        };
      } else {
        console.log(
          "The stored value is not scaled down. Stopping Lambda execution... Please execute again after some time.",
        );
        return {
          statusCode: 400,
          body: JSON.stringify({
            Error: "The environment is already Scaled up.",
          }),
        };
      }
    } else {
      return {
        statusCode: 401,
        body: JSON.stringify({ Message: "Entered token value is incorrect." }),
      };
    }
  } catch (error) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        Error: error,
      }),
    };
  }
};

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

    if (userProvidedToken === userToken || EventBridgeToken === apiToken) {
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
    if (parameterValue === "scaled_down") {
      return true;
    }
    return false;
  } catch (error) {
    console.error("Error retrieving SSM parameter:", error);
    throw error;
  }
};

export const scale_up_handler = async (event) => {
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

        try {
          const clusterName = storedData.cluster_name[0];
          // Retrieve the stored service data from SSM Parameter Store
          const getParameterParams = {
            Name: process.env.ecs_service_data, // Set the path of the stored parameter
          };
          const getECSParameterCommand = new GetParameterCommand(
            getParameterParams,
          );
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
            console.error("Error updating Redis cluster:", error);

            return {
              statusCode: 500,
              body: JSON.stringify({
                error: "Failed to update Redis cluster",
              }),
            };
          }
        } catch (error) {
          console.error("Error updating ECS services:", error);

          return {
            statusCode: 500,
            body: JSON.stringify({
              error: "Failed to update ECS services",
            }),
          };
        }
      } catch (error) {
        console.error("Error updating DB instance:", error);

        return {
          statusCode: 500,
          body: JSON.stringify({
            error: "Failed to update DB instance",
          }),
        };
      }
    } catch (error) {
      console.error("Error updating Auto scaling groups:", error);

      return {
        statusCode: 500,
        body: JSON.stringify({
          error: "Failed to update Auto scaling groups",
        }),
      };
    }

    // return of mail try block
  } catch (error) {
    console.error("Error updating Global scale up:", error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to update Global scale up",
      }),
    };
  }
};

export const waitForInstanceStatus = async (
  desiredStatus,
  redisdesiredStatus,
) => {
  try {
    console.log("Waiting for the update to be done");
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
      console.error("Error waiting for DB instance status:", error);
      throw error;
    }

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
      console.error("Error waiting for redis cluster status:", error);
      throw error;
    }
  } catch (error) {
    console.error("Error waiting for DB/redis cluster status:", error);
    throw error;
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
    console.log("SSM parameter value updated successfully.");
  } catch (error) {
    console.error("Error updating SSM parameter:", error);
    throw error;
  }
};
