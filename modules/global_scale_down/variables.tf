variable "solution_name" {
  type = string
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables related to environment hibernation
# ---------------------------------------------------------------------------------------------------------------------
variable "enable_environment_hibernation_sleep_schedule" {
  type        = bool
  description = "Select true to enable sleep environment hibernation."
  default     = false
}

variable "environment_hibernation_sleep_schedule" {
  type        = string
  description = "Enter schedule details of sleep schedule."
  default     = ""
}

variable "environment_hibernation_wakeup_schedule" {
  type        = string
  description = "Enter schedule details of wakeup schedule."
  default     = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables related to ecs_ec2 instance with name, max_size, min_size, desired_size
# ---------------------------------------------------------------------------------------------------------------------
variable "ecs_ec2_instances_autoscaling_group_arn" {
  description = ""
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables related to NAT instances with name, max_size, min_size, desired_size
# ---------------------------------------------------------------------------------------------------------------------
variable "nat_instances_autoscaling_group_arn" {
  description = ""
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables related to Bastion host instance with name, max_size, min_size, desired_size
# ---------------------------------------------------------------------------------------------------------------------
variable "bastion_host_autoscaling_group_arn" {
  description = ""
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables related to ecs service to work with ecs task count
# ---------------------------------------------------------------------------------------------------------------------
variable "cluster_name" {
  description = ""
  type        = list(string)
}

variable "cluster_arn" {
  description = ""
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# Variable of Database (can be used same for PostgreSQL and mySQL)
# ---------------------------------------------------------------------------------------------------------------------
variable "db_instance_arn" {
  description = ""
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables related to redis database (id, engine name, number of cache node, engine version,subnet group name, and security groups)
# ---------------------------------------------------------------------------------------------------------------------
variable "redis_cluster_arn" {
  description = ""
  type        = list(string)
}

variable "redis_subnet_group_arn" {
  description = ""
  type        = list(string)
}

variable "redis_security_group_arn" {
  description = ""
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# Others
# ---------------------------------------------------------------------------------------------------------------------
variable "cloudfront_arn" {
  description = "cloudfront arn to access the s3 admin website"
  type        = string
}
