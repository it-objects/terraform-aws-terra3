output "cloudfront_domain_name" {
  value       = module.environment.cloudfront_default_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}
