data "aws_region" "current_region" {} # Find region, e.g. us-east-1

# ---------------------------------------------------------------------------------------------------------------------
# Determine cluster id from name (${var.solution_name}-cluster)
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ecs_cluster" "selected" {
  cluster_name = var.container_runtime
}

# ---------------------------------------------------------------------------------------------------------------------
# Determine loadbalancer arn from ssm param store
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ssm_parameter" "alb_arn" {
  name = "/${var.solution_name}/alb_arn"
}

# ---------------------------------------------------------------------------------------------------------------------
## Determine certificate arn from fqdn
# ---------------------------------------------------------------------------------------------------------------------
data "aws_acm_certificate" "certificate" {
  count  = var.lb_domain_name == "" ? 0 : 1
  domain = var.lb_domain_name
}

# ---------------------------------------------------------------------------------------------------------------------
# Determine VPC id from VPC name (${var.solution_name}-vpc)
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.solution_name}/vpc_id"
}

# ---------------------------------------------------------------------------------------------------------------------
# Determine private subnet ids from selected VPC
# Filters by subnet names generated by VPC module (e.g. ito-aws-private-a, ito-aws-private-b)
# ---------------------------------------------------------------------------------------------------------------------
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id.value]
  }

  tags = {
    "Tier" = "private"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Determine security groups
# ---------------------------------------------------------------------------------------------------------------------
data "aws_security_group" "ecs_default_sg" {
  name = "${var.solution_name}_ecs_task_sg"
}

data "aws_security_group" "mysql_marker_sg" {
  name = "${var.solution_name}_mysql_access_marker_sg"
}

data "aws_security_group" "redis_marker_sg" {
  name = "${var.solution_name}_redis_access_marker_sg"
}

data "aws_security_group" "postgres_marker_sg" {
  name = "${var.solution_name}_postgres_access_marker_sg"
}

data "aws_ssm_parameter" "ssm_container_runtime_kms_key_id" {
  count = var.enable_ecs_exec ? 1 : 0
  name  = "/${var.solution_name}/${var.container_runtime}/container_runtime_kms_key_id"
}

# ---------------------------------------------------------------------------------------------------------------------
# Determine KMS key
# ---------------------------------------------------------------------------------------------------------------------
data "aws_kms_key" "solution_key" {
  count  = var.enable_ecs_exec ? 1 : 0
  key_id = data.aws_ssm_parameter.ssm_container_runtime_kms_key_id[0].value
}
