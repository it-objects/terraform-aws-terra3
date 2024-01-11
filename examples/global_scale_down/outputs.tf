output "cloudfront_default_domain_name" {
  value = module.terra3_examples.cloudfront_domain_name
}

output "static_website_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "container_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/api/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "admin_website_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/admin-terra3/"
  description = "URL of admin website for environment hibernation feature."
}
