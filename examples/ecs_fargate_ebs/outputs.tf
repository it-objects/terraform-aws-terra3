# -----------------------------------------------
# ECS Fargate EBS Example - Outputs
# -----------------------------------------------

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.terra3_examples.cloudfront_domain_name
}
