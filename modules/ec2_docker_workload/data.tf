# -----------------------------------------------
# EC2 Docker Workload Module - Data Sources
# -----------------------------------------------

# -----------------------------------------------
# Get Latest Amazon Linux 2023 AMI (ARM64)
# -----------------------------------------------
# Follows the pattern used in bastion_host_ssm module

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp3"]
  }
}

# Optional: Bastion host security group (for allowing bastion access to mapped ports)
# Only fetched if needed - fails gracefully if bastion not deployed
data "aws_security_group" "bastion_host_ssm_sg" {
  name = "${var.solution_name}_bastion_host_ssm_sg"

  # Make this optional - use try() in main.tf to handle missing bastion
}

data "aws_security_group" "ecs_task_sg" {
  name = "${var.solution_name}_ecs_task_sg"

  # Make this optional - use try() in main.tf to handle missing bastion
}

data "aws_security_group" "loadbalancer_sg" {
  name = "${var.solution_name}-loadbalancer_sg"

  # Make this optional - use try() in main.tf to handle missing bastion
}

# -----------------------------------------------
# Get VPC ID from SSM Parameter
# -----------------------------------------------
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.solution_name}/vpc_id"
}

# -----------------------------------------------
# Get Private Subnets for ASG Deployment
# -----------------------------------------------
data "aws_ssm_parameter" "private_subnets" {
  name = "/${var.solution_name}/private_subnets"
}

# -----------------------------------------------
# Get First Private Subnet Details
# -----------------------------------------------
# Used to determine AZ for EBS volume creation
# We extract just the first subnet ID since we only need one AZ
data "aws_subnet" "private_first" {
  id = element(split(",", nonsensitive(data.aws_ssm_parameter.private_subnets.value)), 0)
}

# -----------------------------------------------
# Get Current AWS Region and Account ID
# -----------------------------------------------
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# -----------------------------------------------
# Get Running Instance from ASG (for IP address)
# -----------------------------------------------
# This data source queries running instances in the ASG
# It will be re-queried on every plan/apply to detect IP changes
data "aws_instances" "docker_workload" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.docker_workload.name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [aws_autoscaling_group.docker_workload]
}

# -----------------------------------------------
# Get ALB ARN from SSM Parameter (if ALB enabled)
# -----------------------------------------------

data "aws_ssm_parameter" "alb_arn" {
  count = var.enable_load_balancer && !var.internal_service ? 1 : 0
  name  = "/${var.solution_name}/alb_arn"
}

data "aws_ssm_parameter" "alb_listener_443_arn" {
  count = var.enable_load_balancer && !var.internal_service ? 1 : 0
  name  = "/${var.solution_name}/alb_listener_443_arn"
}

data "aws_ssm_parameter" "alb_listener_80_arn" {
  count = var.enable_load_balancer && !var.internal_service ? 1 : 0
  name  = "/${var.solution_name}/alb_listener_80_arn"
}

# Get ALB details to check if it's HTTPS-enabled
data "aws_lb" "alb" {
  count = var.enable_load_balancer && !var.internal_service ? 1 : 0
  arn   = data.aws_ssm_parameter.alb_arn[0].value
}


# -----------------------------------------------
# Get Internal DNS Zone from SSM (managed by base module)
# -----------------------------------------------

data "aws_ssm_parameter" "internal_dns_zone_id" {
  count = var.enable_internal_dns ? 1 : 0
  name  = "/${var.solution_name}/internal_service_dns/zone_id"
}

data "aws_ssm_parameter" "internal_dns_zone_name" {
  count = var.enable_internal_dns ? 1 : 0
  name  = "/${var.solution_name}/internal_service_dns/zone_name"
}

# Get Route53 Zone Details
data "aws_route53_zone" "internal" {
  count   = var.enable_internal_dns ? 1 : 0
  zone_id = try(data.aws_ssm_parameter.internal_dns_zone_id[0].value, "")
}
