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
  #count = local.create_ecs_with_fargate ? 1 : 0
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

  configuration {
    execute_command_configuration {
      logging = "NONE"
    }
  }
}

/*
resource "aws_ecs_cluster_capacity_providers" "ecs_ec2_cap_provider" {
  count = local.create_ecs_with_ec2 ? 1 : 0
  cluster_name       = aws_ecs_cluster.ec2_cluster[0].name
  capacity_providers = [aws_ecs_capacity_provider.ecs_ec2_capacity_provider[0].name]

  default_capacity_provider_strategy {
    base              = 20
    weight            = 60
    capacity_provider = aws_ecs_capacity_provider.ecs_ec2_capacity_provider[0].name
  }
}*/
