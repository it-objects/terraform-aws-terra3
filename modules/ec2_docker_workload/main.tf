# -----------------------------------------------
# EC2 Docker Workload Module - Main
# -----------------------------------------------

# -----------------------------------------------
# Security Group (if not provided)
# -----------------------------------------------

resource "aws_security_group" "default" {
  count       = length(var.security_group_ids) == 0 ? 1 : 0
  name_prefix = "${var.solution_name}-${var.instance_name}-"
  description = "Security group for ${var.solution_name} ${var.instance_name} Docker workload"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  tags = merge(
    local.common_tags,
    {
      Name = "${var.solution_name}-${var.instance_name}-sg"
    }
  )
}

# -----------------------------------------------
# Security Group Ingress Rules
# -----------------------------------------------

# Allow all ingress traffic (will be gated by network placement)
resource "aws_security_group_rule" "all_ingress" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.default[0].id

  lifecycle {
    create_before_destroy = true
  }
}

# Allow ingress from bastion host on mapped ports (if bastion exists)
resource "aws_security_group_rule" "bastion_to_mapped_ports" {
  # Only create if: (1) we have port mappings, (2) using module-created SG, (3) bastion SG exists
  count = try(
    length(var.port_mappings) > 0 && length(var.security_group_ids) == 0 ? length(var.port_mappings) : 0,
    0
  )

  type                     = "ingress"
  from_port                = var.port_mappings[count.index].hostPort
  to_port                  = var.port_mappings[count.index].hostPort
  protocol                 = var.port_mappings[count.index].protocol
  source_security_group_id = try(data.aws_security_group.bastion_host_ssm_sg.id, null)
  security_group_id        = aws_security_group.default[0].id

  # Skip if bastion security group lookup fails (bastion not deployed)
  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(data.aws_security_group.bastion_host_ssm_sg.id != null, false)
      error_message = "Bastion host security group not found. Skipping bastion ingress rule."
    }
  }
}

# Allow ingress from ECS tasks on mapped ports (if ecs service exists)
resource "aws_security_group_rule" "ecs_task_to_mapped_ports" {
  # Only create if: (1) we have port mappings, (2) using module-created SG, (3) ECS SG exists
  count = try(
    length(var.port_mappings) > 0 && length(var.security_group_ids) == 0 ? length(var.port_mappings) : 0,
    0
  )

  type                     = "ingress"
  from_port                = var.port_mappings[count.index].hostPort
  to_port                  = var.port_mappings[count.index].hostPort
  protocol                 = var.port_mappings[count.index].protocol
  source_security_group_id = try(data.aws_security_group.ecs_task_sg.id, null)
  security_group_id        = aws_security_group.default[0].id

  # Skip if ECS security group lookup fails (ECS not deployed)
  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(data.aws_security_group.ecs_task_sg.id != null, false)
      error_message = "ECS task security group not found. Skipping ECS ingress rule."
    }
  }
}

# Allow all egress traffic
resource "aws_security_group_rule" "all_egress" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.default[0].id

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------

resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/${var.solution_name}/ec2_docker_workload/${var.instance_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# -----------------------------------------------
# User Data Script
# -----------------------------------------------

locals {
  user_data_script = base64gzip(templatefile("${path.module}/user_data.sh", {
    docker_image_uri     = var.docker_image_uri
    docker_env_vars      = local.docker_env_vars
    docker_port_args     = local.docker_port_args
    docker_volume_mounts = local.docker_volume_mounts
    instance_name        = var.instance_name
    log_group_name       = aws_cloudwatch_log_group.docker_logs.name
  }))
}

# -----------------------------------------------
# Launch Template
# -----------------------------------------------

resource "aws_launch_template" "docker_workload" {
  name_prefix            = "${var.solution_name}-${var.instance_name}-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = local.security_groups

  # IMDSv2 Enforcement
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # IAM Instance Profile
  iam_instance_profile {
    arn = aws_iam_instance_profile.docker_workload_profile.arn
  }

  # Root Volume Configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Additional EBS Volumes (for Docker container mounts)
  dynamic "block_device_mappings" {
    for_each = var.ebs_volumes
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.size
        volume_type           = block_device_mappings.value.volume_type
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = true
      }
    }
  }

  # User Data for Docker initialization
  user_data = local.user_data_script

  # Tag volumes
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        LaunchTemplate = "${var.solution_name}-${var.instance_name}-template"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.common_tags
  }

  lifecycle {
    create_before_destroy = true
    # Prevent recreating instances when a new AMI is available
    ignore_changes = [image_id]
  }
}

# -----------------------------------------------
# Auto Scaling Group for Persistent Workload
# -----------------------------------------------
# ASG with min_size=1, max_size=1, desired_capacity=1
# Ensures automatic recovery if instance fails while maintaining single instance

resource "aws_autoscaling_group" "docker_workload" {
  name             = "${var.solution_name}-${var.instance_name}-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = split(",", data.aws_ssm_parameter.private_subnets.value)

  launch_template {
    id      = aws_launch_template.docker_workload.id
    version = "$Latest"
  }

  health_check_grace_period = 300
  default_cooldown          = 300
  health_check_type         = "EC2"

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.min_healthy_percentage
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_role_policy.cloudwatch_logs,
    aws_iam_role_policy_attachment.ssm_managed_instance_core
  ]
}

# -----------------------------------------------
# SSM Parameters for Service Discovery
# -----------------------------------------------

resource "aws_ssm_parameter" "security_group_id" {
  name      = "${local.ssm_param_prefix}/security_group_id"
  type      = "String"
  value     = local.security_groups[0]
  overwrite = true

  tags = local.common_tags
}

resource "aws_ssm_parameter" "log_group_name" {
  name      = "${local.ssm_param_prefix}/log_group_name"
  type      = "String"
  value     = aws_cloudwatch_log_group.docker_logs.name
  overwrite = true

  tags = local.common_tags
}

# Store ASG name for reference
resource "aws_ssm_parameter" "asg_name" {
  name      = "${local.ssm_param_prefix}/asg_name"
  type      = "String"
  value     = aws_autoscaling_group.docker_workload.name
  overwrite = true

  tags = local.common_tags
}
