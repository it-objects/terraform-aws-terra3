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
      ebs_volume = {
        size_in_gb = 5

        snapshot_lifecycle_enabled = true
        snapshot_retention_count   = 3
        backup_enabled             = true
        backup_schedule            = "cron(0 2 ? * * *)"
        backup_retention_count     = 7
      }
    }

    # PostgreSQL client for testing connectivity
    psql_test = {
      instances    = 1
      total_cpu    = 256
      total_memory = 512

      enable_ecs_exec = true

      container = [
        module.container_psql_test
      ]

      internal_service                 = true
      enable_target_group_health_check = false

      execution_iam_access = {
        ssm_parameters = [aws_ssm_parameter.postgres_password.arn]
      }
    }
  }
}

data "aws_region" "current" {}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key -- AWS managed encryption is sufficient for example logs
resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/${local.solution_name}/postgres"
  retention_in_days = 14
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

  # Fast shutdown on SIGTERM: immediately disconnect all clients and stop accepting connections.
  # Without this, PostgreSQL does a "smart shutdown" (waits for clients to disconnect),
  # allowing new writes during the ECS stop grace period that won't be captured in the snapshot.
  command = ["sh", "-c", "trap 'pg_ctl stop -m fast -D \"$PGDATA\" 2>/dev/null; exit 0' SIGTERM; docker-entrypoint.sh postgres & wait $!"]

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
  # sourceVolume must match the ebs_volume name, which defaults to "{component_name}-data"
  mount_points = [
    {
      sourceVolume  = "postgres-data"
      containerPath = "/var/lib/postgresql/data"
      readOnly      = false
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.postgres.name
      "awslogs-region"        = data.aws_region.current.name
      "awslogs-stream-prefix" = "postgres"
    }
  }

  readonlyRootFilesystem = false

  depends_on = [aws_ssm_parameter.postgres_password]
}

# -----------------------------------------------
# Container Definition for PostgreSQL Client (psql)
# -----------------------------------------------

module "container_psql_test" {
  source = "../../modules/container"

  name = "psql-test"

  container_image  = "alpine:latest"
  container_cpu    = 256
  container_memory = 512

  # Install psql client and keep running for ECS exec testing:
  # psql (all connection params injected via env vars and secrets)
  command = ["sh", "-c", "apk add --no-cache postgresql-client && sleep infinity"]

  port_mappings = []

  map_environment = {
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
