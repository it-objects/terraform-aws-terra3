# -----------------------------------------------
# Internal Service DNS Module - Outputs
# -----------------------------------------------

output "zone_id" {
  value       = try(aws_service_discovery_private_dns_namespace.internal[0].hosted_zone, "")
  description = "Route53 private zone ID (created by Cloud Map)"
}

output "zone_name" {
  value       = var.enable ? local.zone_name : ""
  description = "Route53 private zone name"
}

output "zone_arn" {
  value       = try(aws_service_discovery_private_dns_namespace.internal[0].arn, "")
  description = "Cloud Map namespace ARN"
}

output "cloud_map_namespace_id" {
  value       = try(aws_service_discovery_private_dns_namespace.internal[0].id, "")
  description = "Cloud Map private DNS namespace ID for ECS service discovery"
}
