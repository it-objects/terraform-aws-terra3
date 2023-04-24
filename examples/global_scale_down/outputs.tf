output "ecs_cluster_name" {
  value = module.terra3_examples.ecs_cluster_name
}

output "my_app_component_service_names" {
  value = module.terra3_examples.my_app_component_service_names
}

output "my_app_component_ecs_desire_task_counts" {
  value = module.terra3_examples.my_app_component_ecs_desire_task_counts
}

output "db_instance_name" {
  value = module.terra3_examples.db_instance_name
}

output "bastion_host_autoscaling_group_name" {
  value = module.terra3_examples.bastion_host_autoscaling_group_name
}

output "bastion_host_autoscaling_group_max_capacity" {
  value = module.terra3_examples.bastion_host_autoscaling_group_max_capacity
}

output "bastion_host_autoscaling_group_min_capacity" {
  value = module.terra3_examples.bastion_host_autoscaling_group_min_capacity
}

output "bastion_host_autoscaling_group_desired_capacity" {
  value = module.terra3_examples.bastion_host_autoscaling_group_desired_capacity
}

output "nat_instances_autoscaling_group_names" {
  value = module.terra3_examples.nat_instances_autoscaling_group_names
}

output "nat_instances_autoscaling_group_max_capacity" {
  value = module.terra3_examples.nat_instances_autoscaling_group_max_capacity
}

output "nat_instances_autoscaling_group_min_capacity" {
  value = module.terra3_examples.nat_instances_autoscaling_group_min_capacity
}

output "nat_instances_autoscaling_group_desired_capacity" {
  value = module.terra3_examples.nat_instances_autoscaling_group_desired_capacity
}

output "ecs_ec2_instances_autoscaling_group_name" {
  value = module.terra3_examples.ecs_ec2_instances_autoscaling_group_name
}

output "ecs_ec2_instances_autoscaling_group_max_capacity" {
  value = module.terra3_examples.ecs_ec2_instances_autoscaling_group_max_capacity
}

output "ecs_ec2_instances_autoscaling_group_min_capacity" {
  value = module.terra3_examples.ecs_ec2_instances_autoscaling_group_min_capacity
}

output "ecs_ec2_instances_autoscaling_group_desired_capacity" {
  value = module.terra3_examples.ecs_ec2_instances_autoscaling_group_desired_capacity
}

output "redis_cluster_id" {
  value = module.terra3_examples.redis_cluster_id
}

output "redis_engine" {
  value = module.terra3_examples.redis_engine
}

output "redis_node_type" {
  value = module.terra3_examples.redis_node_type
}

output "redis_num_cache_nodes" {
  value = module.terra3_examples.redis_num_cache_nodes
}

output "redis_engine_version" {
  value = module.terra3_examples.redis_engine_version
}

output "redis_subnet_group_name" {
  value = module.terra3_examples.redis_subnet_group_name
}

output "redis_security_group_ids" {
  value = module.terra3_examples.redis_security_group_ids
}




# please delete it once the testing of redis and ecs ec2 asg is done.
output "eecs_ecs_ec2_instances_autoscaling_group_name" {
  value = module.terra3_examples.extra_ecs_ec2_instances_autoscaling_group_name
}

output "eecs_ecs_ec2_instances_autoscaling_group_max_capacity" {
  value = module.terra3_examples.extra_ecs_ec2_instances_autoscaling_group_max_capacity
}

output "eecs_ecs_ec2_instances_autoscaling_group_min_capacity" {
  value = module.terra3_examples.extra_ecs_ec2_instances_autoscaling_group_min_capacity
}

output "eecs_ecs_ec2_instances_autoscaling_group_desired_capacity" {
  value = module.terra3_examples.extra_ecs_ec2_instances_autoscaling_group_desired_capacity
}

output "rredis_redis_cluster_id" {
  value = module.terra3_examples.redis_cluster_id
}

output "rredis_redis_engine" {
  value = module.terra3_examples.redis_engine
}

output "rredis_redis_node_type" {
  value = module.terra3_examples.redis_node_type
}

output "rredis_redis_num_cache_nodes" {
  value = module.terra3_examples.redis_num_cache_nodes
}

output "rredis_redis_engine_version" {
  value = module.terra3_examples.redis_engine_version
}

output "rredis_redis_subnet_group_name" {
  value = module.terra3_examples.redis_subnet_group_name
}

output "rredis_redis_security_group_ids" {
  value = module.terra3_examples.extra_redis_security_group_ids
}
