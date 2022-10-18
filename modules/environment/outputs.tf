output "solution_name" {
  value = var.solution_name
}

output "environment_name" {
  value = var.environment_name
}

output "cloudfront_default_domain_name" {
  value = module.cloudfront_cdn.cloudfront_domain_name
}

output "s3_static_website_bucket" {
  value = module.cloudfront_cdn.s3_static_website_bucket
}

output "lb_domain_name" {
  value = var.create_load_balancer ? module.l7_loadbalancer[0].lb_dns_name : ""
}

output "domain_name" {
  value = length(module.dns_and_certificates) == 0 ? "" : module.dns_and_certificates[0].domain_name
}
