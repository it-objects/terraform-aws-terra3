import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import { RDSClient, StartDBInstanceCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, CreateCacheClusterCommand } from "@aws-sdk/client-elasticache";

export const handler = async(event) => {

    for (let i = 0; i < event.ecs_ec2_instances_asg_names.length; i++){
        const ecs_ec2_asg_input = {
          "AutoScalingGroupName": event.ecs_ec2_instances_asg_names[0],
          "MaxSize": event.ecs_ec2_instances_asg_max_capacity[0],
          "MinSize": event.ecs_ec2_instances_asg_min_capacity[0],
          "DesiredCapacity":event.ecs_ec2_instances_asg_desired_capacity[0],
        };
        const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(ecs_ec2_asg_input);
        const ecs_ec2_asg_client = new AutoScalingClient();
        await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
    }

    for (let i = 0; i < event.nat_instances_asg_names.length; i++){
        const nat_asg_input = {
          "AutoScalingGroupName": event.nat_instances_asg_names[i],
          "MaxSize": event.nat_instances_asg_desired_capacity[i],
          "MinSize": event.nat_instances_asg_desired_capacity[i],
          "DesiredCapacity":event.nat_instances_asg_desired_capacity[i],
        };
        const nat_asg_command = new UpdateAutoScalingGroupCommand(nat_asg_input);
        const nat_asg_client = new AutoScalingClient();
        await nat_asg_client.send(nat_asg_command);
    }

    for (let i = 0; i < event.bastion_host_asg_name.length; i++){
        const bastion_host_asg_input = {
          "AutoScalingGroupName": event.bastion_host_asg_name[0],
          "MaxSize": event.bastion_host_asg_max_capacity[0],
          "MinSize": event.bastion_host_asg_min_capacity[0],
          "DesiredCapacity":event.bastion_host_asg_desired_capacity[0],
        };
        const bastion_host_asg_command = new UpdateAutoScalingGroupCommand(bastion_host_asg_input);
        const bastion_host_asg_client = new AutoScalingClient();
        await bastion_host_asg_client.send(bastion_host_asg_command);
    }

    for (let i = 0; i < event.db_instance_name.length; i++){
        const db_input = {
          "DBInstanceIdentifier": event.db_instance_name,
        };
        const db_command = new StartDBInstanceCommand(db_input);
        const db_client = new RDSClient();
        await db_client.send(db_command);
    }

    for (let i = 0; i < event.redis_cluster_id.length; i++){
        const redis_memory_db = {
          CacheClusterId: event.redis_cluster_id[0],
          NumCacheNodes: event.redis_num_cache_nodes,
          CacheNodeType: event.redis_node_type[0],
          Engine: event.redis_engine[0],
          EngineVersion: event.redis_engine_version[0],
          CacheSubnetGroupName: event.redis_subnet_group_name[0],
          SecurityGroupIds: event.redis_security_group_ids,
        };
        const redis_memory_db_command = new CreateCacheClusterCommand(redis_memory_db);
        const redis_memory_db_client = new ElastiCacheClient();
        await redis_memory_db_client.send(redis_memory_db_command);
    }


    const clusterName = event.cluster_name[0];
    console.log(clusterName);

      try {

      // Retrieve the stored service data from SSM Parameter Store
        const getParameterParams = {
          Name: '/ecs_service_data', // Set the path of the stored parameter
        };
        const getParameterCommand = new GetParameterCommand(getParameterParams);
        const ssmClient = new SSMClient();
        const getParameterResponse = await ssmClient.send(getParameterCommand);

        // Parse the stored service data
        const servicesData = JSON.parse(getParameterResponse.Parameter.Value);


        console.log(servicesData);
        console.log(clusterName);


        // Update the ECS service for each service in the stored data
        for (const serviceData of servicesData) {
          const updateServiceParams = {
            cluster: clusterName, // Specify the ECS cluster name
            service: serviceData.name, // Specify the ECS service name
            desiredCount: serviceData.desiredCount, // Set the desired count for the service
          };
          const updateServiceCommand = new UpdateServiceCommand(updateServiceParams);
          const ecsClient = new ECSClient();
          await ecsClient.send(updateServiceCommand);
        }


        console.log(clusterName);

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
