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
  value       = aws_elasticache_cluster.redis[0].cache_nodes[0].address
  description = "Return Redis endpoint."
}
