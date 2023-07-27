import { ECSClient, UpdateServiceCommand, ListServicesCommand, DescribeServicesCommand } from "@aws-sdk/client-ecs";
import { SSMClient, PutParameterCommand, GetParameterCommand } from "@aws-sdk/client-ssm";
import { RDSClient, StopDBInstanceCommand, DescribeDBInstancesCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, DeleteCacheClusterCommand, DescribeCacheClustersCommand } from "@aws-sdk/client-elasticache";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

export const handleAuthentication = async (event) => {
  try {
    const admin_secret_credentials = process.env.admin_secret_credentials;
    const hashInput = event.queryStringParameters.token;
    console.log("Received token: ", hashInput);

    const secretsManager = new SecretsManagerClient();
    const input = {
      // GetSecretValueRequest
      SecretId: admin_secret_credentials,
    };
    const command = new GetSecretValueCommand(input);
    const secretValue = await secretsManager.send(command);
    const storedHash = JSON.parse(secretValue.SecretString).hash;
    console.log("Stored token: ", storedHash);

    if (hashInput === storedHash) {
      return true;
    }
    return false;
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: "Error",
    };
  }
};

export const checkParameterValue = async (parameterName) => {
  console.log("checking the current hibernation state:- ");
  const getParameterCommand = new GetParameterCommand({
    Name: parameterName,
  });
  try {
    const ssmClient = new SSMClient();
    const response = await ssmClient.send(getParameterCommand);
    const parameterValue = response.Parameter.Value;

    if (parameterValue === "initial" || parameterValue === "scaled_up") {
      return true;
    }
    return false;
  } catch (error) {
    console.error("Error retrieving SSM parameter:", error);
    throw error;
  }
};

export const scale_down_handler = async (event) => {
  console.log("scaling down the deployment:");
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
        body: JSON.stringify({
          error: "No stored parameter found",
        }),
      };
    }
    const storedData = JSON.parse(getParameterResponse.Parameter.Value);

    try {
      for (let i = 0; i < storedData.asg_name.length; i++) {
        const ecs_ec2_asg_input = {
          AutoScalingGroupName: storedData.asg_name[i],
          MaxSize: 0,
          MinSize: 0,
          DesiredCapacity: 0,
        };
        const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(
          ecs_ec2_asg_input,
        );
        const ecs_ec2_asg_client = new AutoScalingClient();
        await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
        console.log(
          `Auto scaling groups "${storedData.asg_name[i]}" updated successfully to 0.`,
        );
      }
      try {
        for (let i = 0; i < storedData.db_instance_name.length; i++) {
          const db_input = {
            DBInstanceIdentifier: storedData.db_instance_name[i],
          };
          const db_command = new StopDBInstanceCommand(db_input);
          const db_client = new RDSClient();
          await db_client.send(db_command);

          console.log(
            `DB instance "${storedData.db_instance_name[i]}" stopped successfully.`,
          );
        }

        try {
          for (let i = 0; i < storedData.redis_cluster_id.length; i++) {
            const redis_memory_db = {
              CacheClusterId: storedData.redis_cluster_id[i],
            };
            const redis_memory_db_command = new DeleteCacheClusterCommand(
              redis_memory_db,
            );
            const redis_memory_db_client = new ElastiCacheClient();
            await redis_memory_db_client.send(redis_memory_db_command);
            console.log(
              `Redis cluster "${storedData.redis_cluster_id[i]}" stopped successfully.`,
            );
          }

          try {
            const clusterName = storedData.cluster_name[0];
            // Call the listServices command to retrieve the list of ECS services
            const listServicesParams = {
              cluster: clusterName,
            };
            const listServicesCommand = new ListServicesCommand(
              listServicesParams,
            );
            const ecsClient = new ECSClient();
            const listServicesResponse = await ecsClient.send(
              listServicesCommand,
            );
            // Extract the service ARNs from the response
            const serviceArns = listServicesResponse.serviceArns;

            // Call the describeServices command to retrieve the list of running services
            const describeServicesParams = {
              cluster: clusterName,
              services: serviceArns,
            };
            const describeServicesCommand = new DescribeServicesCommand(
              describeServicesParams,
            );
            const describeServicesResponse = await ecsClient.send(
              describeServicesCommand,
            );
            // Extract the service names and desired counts from the response
            const servicesData = describeServicesResponse.services.map(
              (service) => ({
                name: service.serviceName,
                desiredCount: service.desiredCount,
              }),
            );

            // Store the service names in SSM Parameter Store
            const putParameterParams = {
              Name: process.env.ecs_service_data, // Set the desired path for the parameter
              Value: JSON.stringify(servicesData), // Store the service names as a comma-separated string
              Type: "String",
              Overwrite: true,
            };
            const putParameterCommand = new PutParameterCommand(
              putParameterParams,
            );
            const ssmClientPut = new SSMClient();
            await ssmClientPut.send(putParameterCommand);
            console.log(
              `The ssm parameter of ECS service stored successfully.`,
            );

            // Update the ECS service for each service in the stored data
            for (const serviceData of servicesData) {
              const updateServiceParams = {
                cluster: clusterName, // Specify the ECS cluster name
                service: serviceData.name, // Specify the ECS service name
                desiredCount: 0, // Set the desired count for the service
              };
              const updateServiceCommand = new UpdateServiceCommand(
                updateServiceParams,
              );
              await ecsClient.send(updateServiceCommand);
              console.log(
                `Desired count of "${serviceData.name}"  set successfully to 0.`,
              );
            }
            return {
              statusCode: 200,
              body: JSON.stringify({
                message: "Successfully updated ECS services",
              }),
            };
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
          console.error("Error updating Redis cluster:", error);

          return {
            statusCode: 500,
            body: JSON.stringify({
              error: "Failed to update Redis cluster",
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
  } catch (error) {
    console.error("Error updating Global scale down:", error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to update Global scale down",
      }),
    };
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
    let isClusterDeleted = false;

    try {
      for (let i = 0; i < storedData.redis_cluster_id.length; i++) {
        console.log("Checking the redis cluster state");
        const redisClient = new ElastiCacheClient();
        const describeCommand = new DescribeCacheClustersCommand({
          CacheClusterId: storedData.redis_cluster_id[0],
        });

        while (!isClusterDeleted) {
          const response = await redisClient.send(describeCommand);
          const clusters = response.CacheClusters;

          const cluster = clusters[0];
          const currentStatus = cluster.CacheClusterStatus;

          console.log(
            `Current status of redis cluster ${storedData.redis_cluster_id[0]}: ${currentStatus}`,
          );

          if (currentStatus !== redisdesiredStatus) {
            console.log(
              `Redis cluster ${storedData.redis_cluster_id[i]} is in the "${redisdesiredStatus}" state.`,
            );
            isClusterDeleted = true;
            break;
          }

          if (!isClusterDeleted) {
            // Wait for 5 seconds before checking the status again
            await new Promise((resolve) => setTimeout(resolve, 5000));
          }
        }
      }
    } catch (error) {
      if (error.name === "CacheClusterNotFoundFault") {
        console.log(`Redis cluster ${storedData.redis_cluster_id[0]} deleted.`);
        isClusterDeleted = true;
      } else {
        console.error("Error while describing Redis cluster:", error);
        throw error;
      }
    }

    try {
      console.log("Checking what is happening inside DB instance");
      for (let i = 0; i < storedData.db_instance_name.length; i++) {
        console.log("Checking the DB instance state");
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
  } catch (error) {
    console.error("Error waiting for DB/redis cluster deleting status:", error);
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

export const handler = async (event) => {
  const parameterName = process.env.hibernation_state;
  const isAuthenticated = await handleAuthentication(event);
  if (isAuthenticated === true) {
    try {
      const isValueValid = await checkParameterValue(parameterName);
      if (isValueValid) {
        console.log(
          "The stored value is valid. Continuing with Lambda execution...",
        );

        await scale_down_handler();
        console.log("Scaling down on resources has been performed.");

        await waitForInstanceStatus("stopped", "deleting");

        await updateParameterValue(parameterName, "scaled_down");
        console.log(
          "Hibernation state has been successfully changed to scaled down.",
        );
        return {
          statusCode: 200,
          body: JSON.stringify({
            Log: "Hibernation state has been successfully changed to scaled down.",
          }),
        };
      } else {
        console.log(
          "The stored value is neither initial nor scaled up. Stopping Lambda execution... Please execute again after some time.",
        );
        return {
          statusCode: 400,
          body: JSON.stringify({
            Error: "The environment is already Scaled down.",
          }),
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
  } else {
    return {
      statusCode: 401,
      body: JSON.stringify({ message: "Entered token value is incorrect." }),
    };
  }
};
