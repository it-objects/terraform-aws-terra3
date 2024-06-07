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

output "s3_static_website_name" {
  value       = module.cloudfront_cdn.s3_static_website_bucket
  description = "Name of S3 static website bucket."
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
  description = "Return ARN of first ECR. Kept for backwards compatibility. See ecr_arns for new out var."
}

output "ecr_arns" {
  value       = try(module.ecr[0], "")
  description = "Return all ARN's of all defined ECR's"
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
