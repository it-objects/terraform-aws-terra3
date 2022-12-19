locals {
  kms_key_id                 = (var.enable_ecs_exec && var.solution_kms_key_id == "") ? aws_kms_key.container_runtime_kms_key[0].key_id : var.solution_kms_key_id
  create_ecs_with_ec2        = var.launch_type == "EC2" ? true : false
  ecs_capacity_providers     = var.launch_type == "EC2" ? aws_ecs_capacity_provider.terra3_ec2_capacity_provider[0].name : var.ecs_cluster_type
  ec2_instance_market_option = var.ecs_cluster_type == "EC2_SPOT" ? "spot" : null
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
resource "aws_ecs_cluster" "cluster" {
  name = var.container_runtime_name

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

resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_provider" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [local.ecs_capacity_providers]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = local.ecs_capacity_providers
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# SSM Parameter
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "ssm_container_runtime_kms_key_id" {
  count = var.enable_ecs_exec ? 1 : 0

  name  = "/${var.solution_name}/${var.container_runtime_name}/container_runtime_kms_key_id"
  type  = "String"
  value = local.kms_key_id
}

resource "aws_ssm_parameter" "ecs_cluster_name" {
  name  = "/${var.solution_name}/${var.container_runtime_name}/container_runtime_ecs_cluster_name"
  type  = "String"
  value = aws_ecs_cluster.cluster.name
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2 capacity provider(ASG) to cluster capacity provider
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "terra3_ec2_capacity_provider" {
  count = local.create_ecs_with_ec2 ? 1 : 0
  name  = "terra3_ec2_capacity_provider"

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
# Auto scaling group and Launch template for ECS Ec2 cluster type.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "ecs_ec2_asg" {
  count               = local.create_ecs_with_ec2 ? 1 : 0
  name                = "terra3_ecs_ec2_autoscaling"
  vpc_zone_identifier = data.aws_subnets.private_subnets.ids

  launch_template {
    id      = aws_launch_template.terra3_ecs_ec2_container_instance[count.index].id
    version = aws_launch_template.terra3_ecs_ec2_container_instance[count.index].latest_version
  }

  protect_from_scale_in     = true
  desired_capacity          = var.cluster_ec2_desired_capacity
  min_size                  = var.cluster_ec2_min_nodes
  max_size                  = var.cluster_ec2_max_nodes
  health_check_grace_period = 300
  health_check_type         = "ELB"
  wait_for_capacity_timeout = "10m"
  wait_for_elb_capacity     = 1


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

resource "aws_launch_template" "terra3_ecs_ec2_container_instance" {
  count                  = local.create_ecs_with_ec2 ? 1 : 0
  name_prefix            = "terra3_ecs_ec2_container_instance"
  image_id               = data.aws_ami.amazon-linux.id
  instance_type          = var.cluster_ec2_instance_type
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

  # trigger to used ec2 instances as spot and accepted values are null, "spot"
  instance_market_options {
    market_type = local.ec2_instance_market_option
  }
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
    enabled = var.cluster_ec2_detailed_monitoring
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_size = var.cluster_ec2_volume_size
      volume_type = "gp2"
    }
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terra3_ecs_ec2_container_instance"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role Definitions of EC2 cluster type deployment
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
