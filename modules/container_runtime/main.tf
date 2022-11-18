locals {
  kms_key_id              = (var.enable_ecs_exec && var.solution_kms_key_id == "") ? aws_kms_key.container_runtime_kms_key[0].key_id : var.solution_kms_key_id
  create_ecs_with_fargate = var.cluster_type == "ECS_FARGATE" ? true : false
  create_ecs_with_ec2     = var.cluster_type == "ECS_EC2" ? true : false
}

#tfsec:ignore:aws-kms-auto-rotate-keys
resource "aws_kms_key" "container_runtime_kms_key" {
  count                   = (var.enable_ecs_exec && var.solution_kms_key_id == "") ? 1 : 0
  description             = "KMS key for container runtime."
  deletion_window_in_days = 7
}

# ---------------------------------------------------------------------------------------------------------------------
# Cluster is compute that service will run on
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "fargate_cluster" {
  count = local.create_ecs_with_fargate ? 1 : 0
  name  = var.container_runtime_name

  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []

    content {
      # enable container insights
      name  = "containerInsights"
      value = "enabled"
    }
  }

  dynamic "configuration" {
    for_each = var.enable_ecs_exec ? [1] : []

    content {
      # enable ECS exec
      execute_command_configuration {
        kms_key_id = local.kms_key_id
        logging    = "NONE" # NONE | DEFAULT | OVERRIDE
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate_cap_provider" {
  count        = local.create_ecs_with_fargate ? 1 : 0
  cluster_name = aws_ecs_cluster.fargate_cluster[0].name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# SSM Parameter
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "ssm_container_runtime_kms_key_id" {
  count = var.enable_ecs_exec ? 1 : 0

  name  = "/${var.environment_name}/${var.container_runtime_name}/container_runtime_kms_key_id"
  type  = "String"
  value = local.kms_key_id
}

resource "aws_ssm_parameter" "ecs_cluster_name" {
  name  = "/${var.environment_name}/${var.container_runtime_name}/container_runtime_ecs_cluster_name"
  type  = "String"
  value = local.create_ecs_with_fargate == true ? aws_ecs_cluster.fargate_cluster[0].name : aws_ecs_cluster.ec2_cluster[0].name
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS with EC2 instances
# ---------------------------------------------------------------------------------------------------------------------
# tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "ec2_cluster" {
  count = local.create_ecs_with_ec2 ? 1 : 0
  name  = var.container_runtime_name

  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []

    content {
      # enable container insights
      name  = "containerInsights"
      value = "enabled"
    }
  }

  dynamic "configuration" {
    for_each = var.enable_ecs_exec ? [1] : []

    content {
      # enable ECS exec
      execute_command_configuration {
        kms_key_id = local.kms_key_id
        logging    = "NONE" # NONE | DEFAULT | OVERRIDE
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_ec2_cap_provider" {
  count              = local.create_ecs_with_ec2 ? 1 : 0
  cluster_name       = aws_ecs_cluster.ec2_cluster[0].name
  capacity_providers = [aws_ecs_capacity_provider.ecs_ec2_capacity_provider[0].name]

  default_capacity_provider_strategy {
    base              = 20
    weight            = 60
    capacity_provider = aws_ecs_capacity_provider.ecs_ec2_capacity_provider[0].name
  }
}

resource "aws_ecs_capacity_provider" "ecs_ec2_capacity_provider" {
  count = local.create_ecs_with_ec2 ? 1 : 0
  name  = "ec2_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_ec2_asg[count.index].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 60
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Auto scaling group and Launch template
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "ecs_ec2_asg" {
  count               = local.create_ecs_with_ec2 ? 1 : 0
  name                = "ecs_ec2_autoscaling"
  vpc_zone_identifier = data.aws_subnets.private_subnets.ids #aws_subnet.private_subnets.*.id

  launch_template {
    id      = aws_launch_template.ecs_ec2_launch_template[count.index].id
    version = aws_launch_template.ecs_ec2_launch_template[count.index].latest_version
  }

  protect_from_scale_in     = true
  desired_capacity          = 2
  min_size                  = 0
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  wait_for_capacity_timeout = "10m"
  wait_for_elb_capacity     = 2


  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}
resource "aws_launch_template" "ecs_ec2_launch_template" {
  count                  = local.create_ecs_with_ec2 ? 1 : 0
  name_prefix            = "ecs_ec2_container_instance"
  image_id               = data.aws_ami.amazon-linux.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [data.aws_security_group.ecs_default_sg.id]
  update_default_version = true
  user_data = base64encode(<<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.container_runtime_name}
    ECS_LOGLEVEL=debug
    EOF
  EOT
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_ec2_role[0].name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  lifecycle {
    create_before_destroy = true
  }
  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ecs_ec2_container_instance"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role Definitions
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_ec2_role" {
  version = "2012-10-17"
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_ec2_role" {
  count              = local.create_ecs_with_ec2 ? 1 : 0
  name               = "EcsCluster_Ec2InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_ec2_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_ecs_role" {
  count      = local.create_ecs_with_ec2 ? 1 : 0
  role       = aws_iam_role.ecs_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  count      = local.create_ecs_with_ec2 ? 1 : 0
  role       = aws_iam_role.ecs_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  count      = local.create_ecs_with_ec2 ? 1 : 0
  role       = aws_iam_role.ecs_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_ec2_role" {
  count = local.create_ecs_with_ec2 ? 1 : 0
  name  = "ec2_role"
  role  = aws_iam_role.ecs_ec2_role[count.index].name
}
