# -----------------------------------------------
# ECS Fargate EBS Example - Variables
# -----------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "solution_name" {
  description = "Solution name (keep short and lowercase)"
  type        = string
  default     = "fgebs"

  validation {
    condition     = length(var.solution_name) <= 16 && can(regex("^([a-z0-9])+(?:-[a-z0-9]+)*$", var.solution_name))
    error_message = "Only max. 16 lower-case alphanumeric characters and dashes are allowed."
  }
}

variable "postgres_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL database password"
  type        = string
  default     = "ChangeMe123!" # IMPORTANT: Change this in production!
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL default database name"
  type        = string
  default     = "myappdb"
}

variable "ebs_volume_availability_zone" {
  description = "Optional. Pin EBS tasks to a single AZ. Leave null for multi-AZ placement."
  type        = string
  default     = null
}
