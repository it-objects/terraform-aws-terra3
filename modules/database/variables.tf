variable "solution_name" {
  type = string
}

variable "db_subnet_group_name" {
  description = "If an existing DB subnet group exists, provide the name"
  type        = string
  default     = ""
}

variable "db_subnet_group_subnet_ids" {
  description = "Subnets to be used in the db subnet group"
  type        = list(string)
  default     = []
}

variable "rds_cluster_identifier" {
  description = "Name of the RDS cluster"
  type        = string
  default     = "rds_cluster"
}

variable "rds_cluster_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 1
}

variable "rds_cluster_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "rds_database"
}

variable "rds_cluster_deletion_protection" {
  description = "If the cluster should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "rds_cluster_enable_cloudwatch_logs_export" {
  description = "Set of log types to export to cloudwatch, valid values are audit, error, general, slowquery, postgresql"
  type        = list(string)
  default     = ["audit"]
}

variable "rds_cluster_engine_version" {
  description = "Engine version to use for the cluster"
  type        = string
  default     = ""
}

variable "rds_cluster_engine" {
  description = "Engine to use for the cluster"
  type        = string
  default     = ""
}

variable "rds_cluster_master_username" {
  description = "Master username for the RDS cluster"
  type        = string
  default     = "root"
}

variable "rds_cluster_preferred_backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter.  Time in UTC."
  type        = string
  default     = "00:00-01:00"
}

variable "rds_cluster_preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur, in (UTC)."
  type        = string
  default     = "sun:01:00-sun:03:00"
}

variable "rds_cluster_skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  type        = bool
  default     = true
}

variable "rds_cluster_instance_instance_class" {
  description = "Database instance type"
  type        = string
  default     = "db.t3.small"
}

variable "rds_cluster_storage_encrypted" {
  description = "Database encryption. Does not work with db.t2.micro"
  type        = bool
  default     = true
}

variable "rds_cluster_multi_az" {
  description = "Multi Availability Zones"
  type        = bool
  default     = true
}

variable "rds_cluster_allocated_storage" {
  description = "allocated_storage"
  type        = number
  default     = 20
}

variable "rds_cluster_max_allocated_storage" {
  description = "max_allocated_storage"
  type        = number
  default     = 20
}

variable "rds_cluster_storage_type" {
  description = "storage_type"
  type        = string
  default     = "gp2"
}

variable "rds_cluster_publicly_accessible" {
  description = "publicly_accessible"
  type        = bool
  default     = false
}

variable "rds_cluster_security_group_ids" {
  description = "Security group ids for db"
  type        = list(string)
}

variable "database" {
  type        = string
  description = "Type of database."
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres"], var.database)
    error_message = "Only 'mysql' and 'postgres' are allowed."
  }
}

variable "ca_cert_identifier" {
  type        = string
  description = "CA certificate."
  default     = "rds-ca-2019"

  validation {
    condition     = contains(["rds-ca-2019", "rds-ca-rsa2048-g1", "rds-ca-rsa4096-g1", "rds-ca-ecc384-g1"], var.ca_cert_identifier)
    error_message = "Only one of the values 'rds-ca-2019', 'rds-ca-rsa2048-g1', 'rds-ca-rsa4096-g1' or 'rds-ca-ecc384-g1' is allowed."
  }
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM authentication in addition to password authentication."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled. Defaults to false."
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data. Valid values are 7, 731 (2 years) or a multiple of 31."
  type        = number
  default     = 7
}
