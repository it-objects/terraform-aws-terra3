# -----------------------------------------------
# Internal Service DNS Module - Main
# -----------------------------------------------

# Plain Route53 private hosted zone for direct record management (EC2 workloads)
resource "aws_route53_zone" "internal" {
  count = var.enable ? 1 : 0

  name = local.zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  # Prevent conflicts with the Cloud Map-managed zone
  lifecycle {
    ignore_changes = [vpc]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.solution_name}-internal-dns"
    }
  )
}

# AWS Cloud Map namespace for ECS service discovery (uses svc. subdomain)
# This automatically creates a separate Route53 private hosted zone
resource "aws_service_discovery_private_dns_namespace" "internal" {
  count = var.enable && var.enable_cloud_map ? 1 : 0

  name        = local.cloud_map_zone_name
  description = "Cloud Map namespace for ${var.solution_name} ECS service discovery"
  vpc         = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.solution_name}-cloud-map-namespace"
    }
  )
}

# Route53 zone ID for EC2 workloads (direct Route53 record management)
resource "aws_ssm_parameter" "zone_id" {
  count     = var.enable ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/zone_id"
  type      = "String"
  value     = aws_route53_zone.internal[0].zone_id
  overwrite = true

  tags = var.tags
}

# Export zone name to SSM Parameter Store for discovery by downstream modules
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
  count     = var.enable && var.enable_cloud_map ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/cloud_map_namespace_id"
  type      = "String"
  value     = aws_service_discovery_private_dns_namespace.internal[0].id
  overwrite = true

  tags = var.tags
}
