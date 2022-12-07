output "cloudfront_default_domain_name" {
  value       = module.mastodon-on-aws.cloudfront_domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "static_website_url" {
  value       = "https://${module.mastodon-on-aws.cloudfront_domain_name}/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "container_url" {
  value       = "https://${module.mastodon-on-aws.cloudfront_domain_name}/api/"
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}

output "domain_name" {
  value       = module.mastodon-on-aws.domain_name
  description = "URL of Cloudfront distribution. Please wait some minutes until the distribution becomes available."
}
