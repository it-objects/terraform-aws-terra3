# -----------------------------------------------
# ECS Fargate EBS Example: PostgreSQL with persistent EBS volume
# -----------------------------------------------
# This example demonstrates deploying a PostgreSQL database
# as an ECS Fargate service with an attached EBS volume for
# persistent storage - no EC2 instance needed.
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

  create_load_balancer = true

  custom_elb_cf_path_patterns = ["/*"]

  enable_s3_for_static_website = false

  create_database = false
  nat             = "NAT_INSTANCES"

  create_bastion_host = true

  enable_ecs_exec = true

  enable_internal_service_dns = true

  # PostgreSQL on Fargate with EBS volume
  app_components = {
    postgres = {
      instances    = 1
      total_cpu    = 512
      total_memory = 1024

      service_port = 5432

      enable_ecs_exec = true

      container = [
        module.container_postgres
      ]

      internal_service = true

      enable_bastion_access = true

      # Service discovery via Cloud Map
      enable_service_discovery   = true
      service_discovery_dns_name = "postgres"

      # Grant execution role access to SSM parameter for secrets
      execution_iam_access = {
        ssm_parameters = [aws_ssm_parameter.postgres_password.arn]
      }

      # EBS volume configuration
      ebs_volumes = [
        {
          name       = "postgres-data"
          size_in_gb = 5
        }
      ]

      ebs_volume_availability_zone = var.ebs_volume_availability_zone

      # Restore from latest snapshot on task launch
      enable_ebs_snapshot_lifecycle = true
    }
  }
}

# -----------------------------------------------
# EBS Snapshot Lifecycle (auto-snapshot on task stop)
# -----------------------------------------------

data "aws_ecs_cluster" "this" {
  cluster_name = "${local.solution_name}-cluster"
  depends_on   = [module.terra3_examples]
}

module "ebs_snapshot_lifecycle" {
  source = "../../modules/ebs_snapshot_lifecycle"

  solution_name            = local.solution_name
  app_component_name       = "postgres"
  cluster_arn              = data.aws_ecs_cluster.this.arn
  ecs_service_name         = "postgresService"
  volume_name              = "postgres-data"
  snapshot_retention_count = 3
}

# -----------------------------------------------
# Store PostgreSQL Password in SSM Parameter Store
# -----------------------------------------------

resource "aws_ssm_parameter" "postgres_password" {
  name        = "/${local.solution_name}/postgres/password"
  description = "PostgreSQL password for ECS Fargate workload"
  type        = "SecureString"
  value       = var.postgres_password
  overwrite   = true

  tags = {
    Name = "${local.solution_name}-postgres-password"
  }
}

# -----------------------------------------------
# Container Definition for PostgreSQL
# -----------------------------------------------

module "container_postgres" {
  source = "../../modules/container"

  name = "postgres"

  container_image  = "postgres:17-alpine"
  container_cpu    = 512
  container_memory = 1024

  port_mappings = [
    {
      containerPort = 5432
      protocol      = "tcp"
    }
  ]

  map_environment = {
    "POSTGRES_USER" = var.postgres_user
    "POSTGRES_DB"   = var.postgres_db
    # Subdirectory within mount to avoid lost+found conflicts
    "PGDATA" = "/var/lib/postgresql/data/db"
  }

  map_secrets = {
    "POSTGRES_PASSWORD" = aws_ssm_parameter.postgres_password.arn
  }

  # Mount the EBS volume into the container
  mount_points = [
    {
      sourceVolume  = "postgres-data"
      containerPath = "/var/lib/postgresql/data"
      readOnly      = false
    }
  ]

  readonlyRootFilesystem = false

  depends_on = [aws_ssm_parameter.postgres_password]
}
