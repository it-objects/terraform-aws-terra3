variable "solution_name" {
  type        = string
  description = "Update your solution name here; max. 8 lower-case characters."
}

variable "environment_name" {
  type        = string
  description = "Name of environment."
  default     = ""
}

variable "cloud_provider" {
  type        = string
  description = ""
  default     = "AWS"

  validation {
    condition     = contains(["AWS"], var.cloud_provider)
    error_message = "One of the specified cloud platforms is invalid. Only 'AWS' is allowed."
  }
}

variable "route53_zone_id" {
  type        = string
  description = "Put in here the zone id of the Hosted Zone to which the subdomain should be added"
  default     = ""
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
  type        = bool
  default     = false
  description = "Enables/disables an AWS Application Load Balancer."
}

variable "create_dns_and_certificates" {
  type        = bool
  default     = false
  description = "Creates DNS entries and certificates to be consumed by other resources."
}

variable "dns_zone_id" {
  type        = string
  description = "Add DNS Zone to automatically create DNS entries per environment. Example: aws-sandbox.terra3.io"
  default     = ""
}

variable "domain_name" {
  type        = string
  description = "Example: aws-sandbox.terra3.io"
  default     = ""
}

variable "private_subnets_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.0.0/24", "172.72.1.0/24"]
}

variable "public_subnets_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.2.0/24", "172.72.3.0/24"]
}

variable "database_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.4.0/24", "172.72.5.0/24"]
}

variable "elasticache_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.6.0/24", "172.72.7.0/24"]
}

variable "azs" {
  type        = list(string)
  description = ""
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "cidr" {
  type        = string
  description = ""
  default     = "172.72.0.0/16"
}

variable "nat_instance_types" {
  type        = list(string)
  description = ""
  default     = ["t4g.nano"] # cheapest
}

variable "create_bastion_host" {
  type        = bool
  description = "Creates a private bastion host reachable via SSM."
  default     = false
}

variable "create_database" {
  type    = bool
  default = false
}

variable "create_ecr" {
  type    = bool
  default = false
}

variable "ecr_access_for_account_id" {
  type    = string
  default = ""
}

variable "create_s3_solution_bucket" {
  type    = bool
  default = false
}

variable "create_deployment_user" {
  type    = bool
  default = false
}

variable "create_newrelic_integration" {
  type    = bool
  default = false
}

variable "newrelic_account_id" {
  type    = string
  default = ""
}

variable "gitlab_url" {
  type    = string
  default = ""
}

variable "add_default_index_html" {
  type    = bool
  default = true
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

variable "enable_s3_for_static_website" {
  description = "Creates an AWS S3 bucket and serve static webpages from it."
  type        = bool
  default     = true
}

variable "app_components" {
  description = "Define here the app_component object. See the examples or documentation for more details."
  type        = any
  default     = {}
}

variable "s3_solution_bucket_policy" {
  type        = string
  description = "Option that generally controls blocking public S3 access."
  default     = "PRIVATE"

  validation {
    condition     = contains(["PRIVATE", "PUBLIC_READ_ONLY"], var.s3_solution_bucket_policy)
    error_message = "Only 'PRIVATE' and 'PUBLIC_READ_ONLY' are allowed."
  }
}

variable "s3_solution_bucket_cloudfront_path" {
  type        = string
  description = "Option that exposes S3 solution bucket via Cloudfront."
  default     = ""
}
