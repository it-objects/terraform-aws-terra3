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

output "ebs_volume_names" {
  value       = module.terra3_examples.ebs_volume_names
  description = "app_component_names"
}

output "container_definitions" {
  value       = module.terra3_examples.json_maps
  description = "container_definitions"
  sensitive    = true
}