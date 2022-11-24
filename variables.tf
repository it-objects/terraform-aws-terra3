variable "solution_name" {
  description = "Enter your solution name here. It will also be reflected in your subdomain name."
  type        = string

  validation {
    condition     = length(var.solution_name) <= 16 && can(regex("^([a-z0-9])+(?:-[a-z0-9]+)*$", var.solution_name))
    error_message = "Only max. 16 lower-case alphanumeric characters and dashes in between are allowed."
  }
}

variable "app_components" {
  description = "Define here the app_component object. See the examples or documentation for more details."
  type        = any
  default     = {}
}

variable "enable_account_best_practices" {
  description = "Should account-wide best practices such as default encryption be applied?"
  type        = bool
  default     = false
}

variable "nat" {
  description = "Select NO_NAT for no NAT, NAT_INSTANCES for NAT based on EC2 instances, or NAT_GATEWAY for NAT with AWS NAT Gateways."
  type        = string
  default     = "NO_NAT"

  validation {
    condition     = contains(["NAT_INSTANCES", "NO_NAT", "NAT_GATEWAY_PER_SUBNET", "NAT_GATEWAY_SINGLE", "NAT_GATEWAY_PER_AZ"], var.nat)
    error_message = "Only 'NO_NAT', 'NAT_INSTANCES', 'NAT_GATEWAY_PER_SUBNET', 'NAT_GATEWAY_SINGLE' and 'NAT_GATEWAY_PER_AZ' are allowed."
  }
}

variable "create_load_balancer" {
  description = "Enables/disables an AWS Application Load Balancer."
  type        = bool
  default     = false
}

variable "create_dns_and_certificates" {
  description = "Creates DNS entries and ACM certificates to be consumed by other resources."
  type        = bool
  default     = false
}

variable "add_default_index_html" {
  description = "Should a default index.html be created in the S3 bucket serving the static web page?"
  type        = bool
  default     = true
}

variable "route53_zone_id" {
  description = "Put in here the zone id of the Route53 Hosted Zone to which the subdomain should be added."
  type        = string
  default     = ""
}

variable "single_az_setup" {
  description = "Multi-AZ is default."
  type        = bool
  default     = false
}

variable "create_bastion_host" {
  description = "Creates a private bastion host reachable via SSM."
  type        = bool
  default     = false
}

variable "create_database" {
  description = "Creates an AWS RDS MySQL database and gives access to it from ECS containers and the bastion host."
  type        = bool
  default     = false
}

variable "create_s3_bucket" {
  description = "Creates an AWS S3 bucket and gives access to it from ECS containers."
  type        = bool
  default     = false
}

variable "enable_ecs_exec" {
  description = "Enables ECS Exec which allows SSH into containers for debugging purposes."
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enables/disables more detailed logging via Container Insights for ECS."
  type        = bool
  default     = false
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
