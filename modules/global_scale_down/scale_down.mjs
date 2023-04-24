import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { RDSClient, StopDBInstanceCommand } from "@aws-sdk/client-rds";
import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ElastiCacheClient, DeleteCacheClusterCommand } from "@aws-sdk/client-elasticache";

export const handler = async(event) => {

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

    for (let i = 0; i < event.ecs_service_name.length; i++){
        const ecs_input = {
          "cluster": event.cluster_name[i],
          "service": event.ecs_service_name[i],
          "desiredCount": 0,
        };
        const ecs_command = new UpdateServiceCommand(ecs_input);
        const ecs_client = new ECSClient();
        await ecs_client.send(ecs_command);
    }

    for (let i = 0; i < event.db_instance_name.length; i++){
        const db_input = {
          "DBInstanceIdentifier": event.db_instance_name[i],
        };
        const db_command = new StopDBInstanceCommand(db_input);
        const db_client = new RDSClient();
        await db_client.send(db_command);
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

    for (let i = 0; i < event.ecs_ec2_instances_autoscaling_group_name.length; i++){
        const ecs_ec2_asg_input = {
          "AutoScalingGroupName": event.ecs_ec2_instances_autoscaling_group_name[i],
          "MaxSize": 0,
          "MinSize": 0,
          "DesiredCapacity": 0,
        };
        const ecs_ec2_asg_command = new UpdateAutoScalingGroupCommand(ecs_ec2_asg_input);
        const ecs_ec2_asg_client = new AutoScalingClient();
        await ecs_ec2_asg_client.send(ecs_ec2_asg_command);
    }

    for (let i = 0; i < event.redis_cluster_id.length; i++){
        const redis_memory_db = {
          CacheClusterId: event.redis_cluster_id[i],
        };
        const redis_memory_db_command = new DeleteCacheClusterCommand(redis_memory_db);
        const redis_memory_db_client = new ElastiCacheClient();
        await redis_memory_db_client.send(redis_memory_db_command);
    }
};
