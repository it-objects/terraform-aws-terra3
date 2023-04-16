import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { RDSClient, StopDBInstanceCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, DeleteCacheClusterCommand } from "@aws-sdk/client-elasticache";

export const handler = async(event) => {

    for (let i = 0; i < event.nat_instances_asg_names.length; i++){
        const nat_asg_input = {
          "AutoScalingGroupName": event.nat_instances_asg_names[i],
          "MaxSize": event.nat_instances_asg_max_capacity[0],
          "MinSize": event.nat_instances_asg_min_capacity[0],
          "DesiredCapacity":event.nat_instances_asg_desired_capacity[0],
        };
        const nat_asg_command = new UpdateAutoScalingGroupCommand(nat_asg_input);
        const nat_asg_client = new AutoScalingClient();
        await nat_asg_client.send(nat_asg_command);
        (err, data) => {
            if (err) {
              console.log(`Error updating Auto Scaling group ${event.nat_instances_asg_names[i]}: ${err}`);
            } else {
              console.log(`Successfully updated Auto Scaling group ${event.nat_instances_asg_names[i]}: ${data}`);
            }
          };
    }

    const ecs_input = {
      "cluster": event.cluster_name[0],
      "service": event.ecs_service_name[0],
      "desiredCount": event.ecs_desire_task_count[0],
    };
    const ecs_command = new UpdateServiceCommand(ecs_input);
    const ecs_client = new ECSClient();
    await ecs_client.send(ecs_command);

    const db_input = {
      "DBInstanceIdentifier": event.db_instance_name[0],
    };
    const db_command = new StopDBInstanceCommand(db_input);
    const db_client = new RDSClient();
    await db_client.send(db_command);

    const bastion_host_asg_input = {
      "AutoScalingGroupName": event.bastion_host_asg_name[0],
      "MaxSize": event.bastion_host_asg_max_capacity[0],
      "MinSize": event.bastion_host_asg_min_capacity[0],
      "DesiredCapacity":event.bastion_host_asg_desired_capacity[0],
    };
    const bastion_host_asg_command = new UpdateAutoScalingGroupCommand(bastion_host_asg_input);
    const bastion_host_asg_client = new AutoScalingClient();
    await bastion_host_asg_client.send(bastion_host_asg_command);

    const ecs_ec2_asg_input = {
      "AutoScalingGroupName": event.ecs_ec2_instances_asg_name[0],
      "MaxSize": event.ecs_ec2_instances_asg_max_capacity[0],
      "MinSize": event.ecs_ec2_instances_asg_min_capacity[0],
      "DesiredCapacity":event.ecs_ec2_instances_asg_desired_capacity[0],
    };
    const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(ecs_ec2_asg_input);
    const ecs_ec2_asg_client = new AutoScalingClient();
    await ecs_ec2_asg_client.send(ecs_ec2_asg_command);

    const redis_memory_db = {
      CacheClusterId: event.redis_cluster_id[0],
    };
    const redis_memory_db_command = new DeleteCacheClusterCommand(redis_memory_db);
    const redis_memory_db_client = new ElastiCacheClient();
    await redis_memory_db_client.send(redis_memory_db_command);


};
