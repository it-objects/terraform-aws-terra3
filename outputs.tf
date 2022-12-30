output "cloudfront_domain_name" {
  value       = module.cloudfront_cdn.cloudfront_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "domain_name" {
  value       = local.domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "s3_solution_bucket_name" {
  value       = var.create_s3_solution_bucket ? module.s3_solution_bucket[0].s3_solution_bucket_name : ""
  description = "Return solution bucket's URL."
}

output "db_credentials" {
  value       = var.create_database ? module.database[0].db_credentials : ""
  description = "Return DB credentials as JSON."
}

output "redis_endpoint" {
  value       = var.create_elasticache_redis ? aws_elasticache_cluster.redis[0].cache_nodes[0].address : ""
  description = "Return Redis endpoint."
}

output "sns_topic_arn" {
  value       = aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn
  description = "SNS topic arn"
}
