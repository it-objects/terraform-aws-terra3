# -----------------------------------------------
# EC2 Docker Workload Example: PostgreSQL with ECS Testing
# -----------------------------------------------
# This example demonstrates deploying a PostgreSQL database
# as a persistent Docker workload on EC2.
#
# An ECS service runs a PostgreSQL test container that can
# connect to the EC2-hosted database for connectivity testing.
# -----------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  solution_name = var.solution_name
}

# -----------------------------------------------
# Deploy Terra3 Infrastructure
# -----------------------------------------------

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # Infrastructure
  create_load_balancer = true # Required for app_components (even internal services)

  custom_elb_cf_path_patterns = ["/*"]

  enable_s3_for_static_website = false

  create_database = false
  nat             = "NAT_INSTANCES" # Required for container image pulls

  create_bastion_host = true
  enable_ecs_exec     = true # Required for app_components with enable_ecs_exec

  # App component for testing PostgreSQL connectivity
  app_components = {
    psql_test = {
      instances    = 1
      total_cpu    = 256
      total_memory = 512

      enable_ecs_exec = true

      container = [
        module.container_psql_test
      ]

      internal_service                 = true # No external routing
      enable_target_group_health_check = false
    }
  }
}

# -----------------------------------------------
# Store PostgreSQL Password in SSM Parameter Store (SecureString)
# -----------------------------------------------

resource "aws_ssm_parameter" "postgres_password" {
  name        = "/${local.solution_name}/postgres/password"
  description = "PostgreSQL password for ECS tasks"
  type        = "SecureString"
  value       = var.postgres_password
  overwrite   = true

  tags = {
    Name    = "${local.solution_name}-postgres-password"
    Purpose = "PostgreSQL password for ECS tasks"
  }
}

# Grant ECS task execution role permission to read the parameter
# (SSM parameters are accessible via IMDSv2 without VPC endpoints)

# -----------------------------------------------
# Container Definition for PostgreSQL Testing
# -----------------------------------------------

module "container_psql_test" {
  source = "../../modules/container"

  name = "psql-test"

  container_image  = "alpine:latest"
  container_cpu    = 256
  container_memory = 512

  # just keep running
  # connection to ec2 docker hosted postgres db can be tested via ecs exec from the container shell:
  # psql
  # (all connection parameters are injected via environment variables and secrets)
  command = ["sh", "-c", "apk add --no-cache postgresql-client && sleep infinity"]

  port_mappings = []

  map_environment = {
    # PGHOST uses the module's automatic internal DNS configuration
    # Default format: {instance_name}.internal.{solution_name}.local
    "PGHOST"     = "postgres.internal.${local.solution_name}.local"
    "PGPORT"     = "5432"
    "PGUSER"     = var.postgres_user
    "PGDATABASE" = var.postgres_db
  }

  map_secrets = {
    "PGPASSWORD" = aws_ssm_parameter.postgres_password.arn
  }

  readonlyRootFilesystem = false

  depends_on = [aws_ssm_parameter.postgres_password]
}

# -----------------------------------------------
# EC2 Docker Workload - PostgreSQL Database
# -----------------------------------------------

module "postgres_docker" {
  source = "../../modules/ec2_docker_workload"

  solution_name = local.solution_name
  instance_name = "postgres"

  # Docker Configuration
  docker_image_uri = "postgres:15-alpine"

  # Port Mappings
  port_mappings = [
    {
      containerPort = 5432
      hostPort      = 5432
      protocol      = "tcp"
    }
  ]

  # Environment Variables
  # Important: PGDATA uses a subdirectory to avoid "directory not empty" errors
  # when EBS volumes contain lost+found directory from formatting
  environment_variables = {
    "POSTGRES_USER"     = var.postgres_user
    "POSTGRES_PASSWORD" = var.postgres_password
    "POSTGRES_DB"       = var.postgres_db
    "PGDATA"            = "/var/lib/postgresql/data/db" # Subdirectory within mount
  }

  # EBS Volume Configuration
  # Mount a persistent volume for database data
  ebs_volumes = [
    {
      size                  = 50
      mount_path            = "/var/lib/postgresql/data"
      delete_on_termination = false # Keep data on instance termination
    }
  ]

  # CloudWatch Logs
  log_retention_days = 7

  # Backup Configuration
  enable_backup         = true
  backup_retention_days = 7
  backup_schedule       = "cron(0 2 ? * * *)" # Daily at 2 AM UTC

  # Internal DNS is enabled by default
  # The Route53 zone is created by the Terra3 base module
  # This module automatically creates DNS A records for service discovery

  # Explicit dependency to ensure VPC and subnets are created first
  depends_on = [module.terra3_examples]
}

module "nginx_docker" {
  source = "../../modules/ec2_docker_workload"

  solution_name = local.solution_name
  instance_name = "nginx"

  # Docker Configuration
  docker_image_uri = "nginx:latest"

  # Port Mappings
  port_mappings = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]

  # CloudWatch Logs
  log_retention_days = 7

  # Explicit dependencies to ensure proper deployment order and SSM access
  # Note: nginx depends on postgres being fully deployed to avoid race conditions
  # with security group and Route53 zone initialization
  depends_on = [
    module.terra3_examples,
    module.postgres_docker
  ]
}

# -----------------------------------------------
# Grant ECS Task Role Access to SSM Parameter Store
# -----------------------------------------------

data "aws_iam_role" "ecs_task_execution_role" {
  name = "psql_test-ExecutionRole"

  depends_on = [module.terra3_examples]
}

resource "aws_iam_role_policy" "ecs_task_ssm_access" {
  name = "${local.solution_name}-postgres-ssm-access"
  role = data.aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = aws_ssm_parameter.postgres_password.arn
      }
    ]
  })
}
