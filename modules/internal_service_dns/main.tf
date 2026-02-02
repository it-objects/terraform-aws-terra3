# -----------------------------------------------
# Internal Service DNS Module - Main
# -----------------------------------------------

# Route53 private hosted zone for internal service discovery
# This zone is created once at the VPC level and shared by all Docker workloads
resource "aws_route53_zone" "internal" {
  count = var.enable ? 1 : 0
  name  = local.zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.solution_name}-internal-zone"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Export zone ID to SSM Parameter Store for discovery by ec2_docker_workload modules
resource "aws_ssm_parameter" "zone_id" {
  count     = var.enable ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/zone_id"
  type      = "String"
  value     = aws_route53_zone.internal[0].zone_id
  overwrite = true

  tags = var.tags
}

# Export zone name to SSM Parameter Store for discovery by ec2_docker_workload modules
resource "aws_ssm_parameter" "zone_name" {
  count     = var.enable ? 1 : 0
  name      = "/${var.solution_name}/internal_service_dns/zone_name"
  type      = "String"
  value     = aws_route53_zone.internal[0].name
  overwrite = true

  tags = var.tags
}
