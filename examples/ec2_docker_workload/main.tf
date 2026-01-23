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
# Container Definition for PostgreSQL Testing
# -----------------------------------------------

module "container_psql_test" {
  source = "../../modules/container"

  name = "psql-test"

  container_image  = "alpine:latest"
  container_cpu    = 256
  container_memory = 512

  # just keep running 
  # connection to ec2 docker hosted postgres db can be tested via ecs exec
  command = ["sh", "-c", "apk add --no-cache postgresql-client && sleep infinity"]

  port_mappings = []

  map_environment = {
    "PGHOST"     = "postgres"
    "PGPORT"     = "5432"
    "PGUSER"     = var.postgres_user
    "PGPASSWORD" = var.postgres_password
    "PGDATABASE" = var.postgres_db
  }

  readonlyRootFilesystem = false
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
      size       = 50
      mount_path = "/var/lib/postgresql/data"
      #delete_on_termination = false # Keep data on instance termination
    }
  ]

  # CloudWatch Logs
  log_retention_days = 7

  # Backup Configuration
  enable_backup         = true
  backup_retention_days = 7
  backup_schedule       = "cron(0 2 ? * * *)" # Daily at 2 AM UTC

  # Explicit dependency to ensure VPC and subnets are created first
  depends_on = [module.terra3_examples]
}

# -----------------------------------------------
# Store PostgreSQL Endpoint in SSM Parameter Store
# (For other services to discover)
# -----------------------------------------------

resource "aws_ssm_parameter" "postgres_endpoint" {
  name  = "/${local.solution_name}/postgres/endpoint"
  type  = "String"
  value = "postgres:5432" # Hostname resolvable from ECS tasks via Docker bridge

  tags = {
    Name    = "${local.solution_name}-postgres-endpoint"
    Purpose = "Service discovery for PostgreSQL"
  }
}
