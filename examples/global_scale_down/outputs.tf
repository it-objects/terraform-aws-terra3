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
  value = (module.terra3_examples.nat_instances_autoscaling_group_names)
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
