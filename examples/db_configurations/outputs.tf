output "cloudfront_default_domain_name" {
  value = module.terra3_examples.cloudfront_domain_name
}

output "static_website_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "static_website_url_external" {
  value       = "https://${module.terra3_examples.domain_name}/"
  description = "URL of Cloudfront distribution's custom domain. Please wait some minutes until the distribution becomes available."
}

output "container_url" {
  value       = "https://${module.terra3_examples.cloudfront_domain_name}/api/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "container_url_external" {
  value       = "https://${module.terra3_examples.domain_name}/api/"
  description = "URL of Cloudfront distribution's custom domain. Please wait some minutes until the distribution becomes available."
}
