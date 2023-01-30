output "hosted_zone_id" {
  value = local.zone_id
}

output "hosted_zone_name_servers" {
  value = local.name_servers
}

output "domain_name" {
  value = aws_acm_certificate.domain_certificate.domain_name
}

output "subject_alternative_names" {
  value = aws_acm_certificate.domain_certificate.subject_alternative_names
}

output "cloudfront_certificate_arn" {
  value = aws_acm_certificate.domain_certificate.arn
}
