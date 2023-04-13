output "cloudfront_domain_name" {
  value       = module.cloudfront_cdn.cloudfront_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "cloudfront_arn" {
  value       = module.cloudfront_cdn.cloudfront_arn
  description = "ARN of Cloudfront distribution."
}

output "s3_static_website_arn" {
  value       = module.cloudfront_cdn.s3_static_website_arn
  description = "ARN of S3 static website bucket."
}

output "domain_name" {
  value       = local.domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "s3_solution_bucket_name" {
  value       = var.create_s3_solution_bucket ? module.s3_solution_bucket[0].s3_solution_bucket_name : ""
  description = "Return solution bucket's URL."
}

output "s3_solution_bucket_arn" {
  value       = var.create_s3_solution_bucket ? module.s3_solution_bucket[0].s3_bucket_arn : ""
  description = "Return solution bucket's ARN."
}

output "db_credentials" {
  value       = var.create_database ? module.database[0].db_credentials : ""
  description = "Return DB credentials as JSON."
}

output "redis_endpoint" {
  value       = var.create_elasticache_redis ? aws_elasticache_cluster.redis[0].cache_nodes[0].address : ""
  description = "Return Redis endpoint."
}

output "ecr_arn" {
  value       = try(module.ecr[0].ecr_arn, "")
  description = "Return ARN of ecr if enabled."
}

output "vpc_id" {
  value       = local.vpc_id
  description = "Return vpc_id of VPC in use."
}

output "public_subnets" {
  value       = local.public_subnets
  description = "Return public_subnets of VPC in use."
}

output "private_subnets" {
  value       = local.private_subnets
  description = "Return private_subnets of VPC in use."
}

output "private_route_table_ids" {
  value       = local.private_route_table_ids
  description = "Return private_route_table_ids of VPC in use."
}

output "db_subnet_group_name" {
  value       = local.db_subnet_group_name
  description = "Return db_subnet_group_name of VPC in use."
}

output "elasticache_subnet_ids" {
  value       = local.elasticache_subnet_ids
  description = "Return elasticache_subnet_ids of VPC in use."
}

output "ecs_cluster_name" {
  value = module.cluster.ecs_cluster_name
}

output "my_app_component" {
  value = keys(module.app_components.app_components)
}

output "my_app_component_service_names" {
  value = local.ecs_service_names
}

output "my_app_component_ecs_desire_task_counts" {
  value = local.ecs_desire_task_counts
}

output "db_instance_name" {
  value = local.db_instance_name
}

output "bastion_host_autoscaling_group_name" {
  value = module.bastion_host_ssm[*].bastion_host_autoscaling_group_name
}

output "bastion_host_autoscaling_group_max_capacity" {
  value = module.bastion_host_ssm[*].bastion_host_autoscaling_group_max_capacity
}

output "bastion_host_autoscaling_group_min_capacity" {
  value = module.bastion_host_ssm[*].bastion_host_autoscaling_group_min_capacity
}

output "bastion_host_autoscaling_group_desired_capacity" {
  value = module.bastion_host_ssm[*].bastion_host_autoscaling_group_desired_capacity
}

output "nat_instances_autoscaling_group_names" {
  value = local.nat_instances_autoscaling_group_names
}

output "nat_instances_autoscaling_group_max_capacity" {
  value = local.nat_instances_asg_max_capacity
}

output "nat_instances_autoscaling_group_min_capacity" {
  value = local.nat_instances_asg_min_capacity
}

output "nat_instances_autoscaling_group_desired_capacity" {
  value = local.nat_instances_asg_desired_capacity
}

output "ecs_ec2_instances_autoscaling_group_name" {
  value = local.ecs_ec2_instances_autoscaling_group_name
}

output "ecs_ec2_instances_autoscaling_group_max_capacity" {
  value = local.ecs_ec2_instances_asg_max_capacity
}

output "ecs_ec2_instances_autoscaling_group_min_capacity" {
  value = local.ecs_ec2_instances_asg_min_capacity
}

output "ecs_ec2_instances_autoscaling_group_desired_capacity" {
  value = local.ecs_ec2_instances_asg_desired_capacity
}
