output "cloudfront_domain_name" {
  value       = module.environment.cloudfront_default_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "domain_name" {
  value       = module.environment.domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "s3_solution_bucket_name" {
  value       = module.environment.s3_solution_bucket_name
  description = "Return solution bucket's URL."
}

output "db_credentials" {
  value       = module.environment.db_credentials
  description = "Return DB credentials as JSON."
}

output "redis_endpoint" {
  value       = module.environment.redis_endpoint
  description = "Return id of VPC."
}
