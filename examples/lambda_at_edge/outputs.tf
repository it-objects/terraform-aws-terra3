output "cloudfront_default_domain_name" {
  value       = module.terra3_examples.cloudfront_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "static_website_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "container_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/api/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "lambda_at_edge_arn" {
  value       = module.lambda_at_edge_example.lambda_at_edge_arn
  description = "ARN of lambda at edge function."
}

output "lambda_at_edge_arn_version" {
  value       = module.lambda_at_edge_example.lambda_at_edge_version
  description = "Version of lambda at edge function."
}
