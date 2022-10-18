output "cloudfront_default_domain_name" {
  value       = module.terra3_examples.cloudfront_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}
