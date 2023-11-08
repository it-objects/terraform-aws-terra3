# ---------------------------------------------------------------------------------------------------------------------
# Database module
# ---------------------------------------------------------------------------------------------------------------------

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "random_pet" "this" {
  length = 1
}

# as this is meant for testing purposes, costs are higher weighted than medium or low security related aspects
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.solution_name}/db_credentials_${random_pet.this.id}/"
  description = "Secrets for ${var.solution_name} DB."
}

locals {
  secret_string = jsonencode({
    DB_HOST           = aws_db_instance.db.address
    DB_USER           = var.rds_cluster_master_username
    DB_PASSWORD       = random_password.db_password.result
    DB_NAME           = var.rds_cluster_database_name
    DB_PORT           = aws_db_instance.db.port
    CONNECTION_STRING = "Server=${aws_db_instance.db.address}; Port=${aws_db_instance.db.port}; Database=${var.rds_cluster_database_name}; Uid=${var.rds_cluster_master_username}; Pwd=${random_password.db_password.result}; SslMode=none;"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = local.secret_string
}

resource "aws_ssm_parameter" "db_credentials_arn" {
  name  = "/${var.solution_name}/db_credentials_arn"
  type  = "String"
  value = aws_secretsmanager_secret_version.db_credentials_version.arn
}

# as this is meant for testing purposes, costs are higher weighted than medium or low security related aspects
#tfsec:ignore:aws-rds-enable-performance-insights
resource "aws_db_instance" "db" {
  allocated_storage               = var.rds_cluster_allocated_storage
  max_allocated_storage           = var.rds_cluster_max_allocated_storage
  identifier                      = var.rds_cluster_database_name
  db_name                         = var.rds_cluster_database_name
  username                        = var.rds_cluster_master_username
  password                        = random_password.db_password.result
  multi_az                        = var.rds_cluster_multi_az
  backup_retention_period         = var.rds_cluster_backup_retention_period
  deletion_protection             = var.rds_cluster_deletion_protection #tfsec:ignore:AVD-AWS-0177
  enabled_cloudwatch_logs_exports = var.rds_cluster_enable_cloudwatch_logs_export
  engine_version                  = var.rds_cluster_engine_version
  engine                          = var.rds_cluster_engine
  backup_window                   = var.rds_cluster_preferred_backup_window
  maintenance_window              = var.rds_cluster_preferred_maintenance_window
  storage_encrypted               = var.rds_cluster_storage_encrypted
  storage_type                    = var.rds_cluster_storage_type
  skip_final_snapshot             = var.rds_cluster_skip_final_snapshot
  instance_class                  = var.rds_cluster_instance_instance_class
  publicly_accessible             = var.rds_cluster_publicly_accessible
  db_subnet_group_name            = var.db_subnet_group_name
  vpc_security_group_ids          = var.rds_cluster_security_group_ids
  parameter_group_name            = var.database == "mysql" ? aws_db_parameter_group.mysql_logbin_parameter_group[0].name : null

  # default: rds-ca-2019 (expires Aug 2024); newer options are: rds-ca-rsa2048-g1, rds-ca-rsa4096-g1 or rds-ca-ecc384-g1
  ca_cert_identifier = var.ca_cert_identifier

  iam_database_authentication_enabled = var.iam_database_authentication_enabled #tfsec:ignore:AVD-AWS-0176

  # Enhanced monitoring
  monitoring_interval = var.monitoring_interval # 0 means disabled
  monitoring_role_arn = var.monitoring_interval == 0 ? null : aws_iam_role.rds_enhanced_monitoring[0].arn

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  #performance_insights_kms_key_id = "" # => leave emtpy to pick default aws/rds

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

################################################################################
# Create an IAM role to allow enhanced monitoring
################################################################################

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval == 0 ? 0 : 1

  name_prefix        = "rds-enhanced-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring[0].json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval == 0 ? 0 : 1

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  count = var.monitoring_interval == 0 ? 0 : 1

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# attention: change requires restart of rds instance without failover!
# set apply_method temporarily to "immediate" for non-prod environments
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_db_parameter_group" "mysql_logbin_parameter_group" {
  count = var.database == "mysql" ? 1 : 0

  name        = "${var.solution_name}-mysql-logbin-parameters"
  family      = (split(".", var.rds_cluster_engine_version)[0] == "8") ? "mysql8.0" : "mysql5.7"
  description = "RDS parameter group for ${var.solution_name} allowing stored procedures."

  parameter {
    name         = "log_bin_trust_function_creators"
    value        = "1"
    apply_method = "pending-reboot"
  }
}
