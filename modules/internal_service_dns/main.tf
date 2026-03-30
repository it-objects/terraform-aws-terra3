# -----------------------------------------------
# Internal Service DNS Module - Main
# -----------------------------------------------

# AWS Cloud Map namespace for ECS service discovery
# This automatically creates a Route53 private hosted zone for the domain
resource "aws_service_discovery_private_dns_namespace" "internal" {
  count = var.enable ? 1 : 0

  name        = local.zone_name
  description = "Cloud Map namespace for ${var.solution_name} ECS service discovery"
  vpc         = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.solution_name}-cloud-map-namespace"
    }
  )
}

# Export zone ID to SSM Parameter Store for discovery by ec2_docker_workload modules
resource "aws_ssm_parameter" "zone_id" {
  count     = var.enable ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/zone_id"
  type      = "String"
  value     = aws_service_discovery_private_dns_namespace.internal[0].hosted_zone
  overwrite = true

  tags = var.tags
}

# Export zone name to SSM Parameter Store for discovery by ec2_docker_workload modules
resource "aws_ssm_parameter" "zone_name" {
  count     = var.enable ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/zone_name"
  type      = "String"
  value     = local.zone_name
  overwrite = true

  tags = var.tags
}

# Export Cloud Map namespace ID to SSM for ECS service discovery
resource "aws_ssm_parameter" "cloud_map_namespace_id" {
  count     = var.enable ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/cloud_map_namespace_id"
  type      = "String"
  value     = aws_service_discovery_private_dns_namespace.internal[0].id
  overwrite = true

  tags = var.tags
}
