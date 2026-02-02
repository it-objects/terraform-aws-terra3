# -----------------------------------------------
# Internal Service DNS Module - Outputs
# -----------------------------------------------

output "zone_id" {
  value       = try(aws_route53_zone.internal[0].zone_id, "")
  description = "Route53 private zone ID"
}

output "zone_name" {
  value       = try(aws_route53_zone.internal[0].name, "")
  description = "Route53 private zone name"
}

output "zone_arn" {
  value       = try(aws_route53_zone.internal[0].arn, "")
  description = "Route53 private zone ARN"
}
