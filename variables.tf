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

variable "create_s3_solution_bucket" {
  description = "Creates an AWS S3 bucket and gives access to it from ECS containers."
  type        = bool
  default     = false
}

variable "s3_bucket_policy" {
  type        = string
  description = "Option that generally controls blocking public S3 access."
  default     = "PRIVATE"

  validation {
    condition     = contains(["PRIVATE", "PUBLIC_READ_ONLY"], var.s3_bucket_policy)
    error_message = "Only 'PRIVATE' and 'PUBLIC_READ_ONLY' are allowed."
  }
}

variable "s3_solution_bucket_cf_behaviours" {
  type        = list(any)
  description = "Option that exposes S3 solution bucket via Cloudfront with different behaviours."
  default     = []
}

variable "enable_s3_for_static_website" {
  description = "Creates an AWS S3 bucket and serve static webpages from it."
  type        = bool
  default     = true
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

variable "cluster_type" {
  description = "Select FARGATE for cluster type as FARGATE, or select EC2 for cluster type as EC2."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.cluster_type)
    error_message = "Only 'FARGATE', and 'EC2' are allowed."
  }
}

variable "cluster_ec2_min_nodes" {
  description = "Select the minimum nodes of the EC2 instances."
  type        = number
  default     = 1
}

variable "cluster_ec2_max_nodes" {
  description = "Select the maximum nodes of the EC2 instances."
  type        = number
  default     = 2
}

variable "cluster_ec2_instance_type" {
  description = "Select instance type of the EC2 instances."
  type        = string
  default     = "t3a.small"
}

variable "cluster_ec2_desired_capacity" {
  description = "Select desired capacity of the EC2 instances."
  type        = number
  default     = 1
}

variable "cluster_ec2_detailed_monitoring" {
  description = "Select the detailed monitoring of the EC2 instances."
  type        = bool
  default     = false
}

variable "cluster_ec2_volume_size" {
  description = "Select the ebs volume size of the EC2 instances."
  type        = number
  default     = 30
}

variable "launch_type" {
  description = "Select FARGATE for launch type as FARGATE, or select EC2 for launch type as EC2."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "Only 'FARGATE', and 'EC2' are allowed."
  }
}
#####

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

variable "create_elasticache_redis" {
  type        = bool
  description = "Creates AWS Redis cluster."
  default     = false
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

variable "enable_alb_logs" {
  type        = bool
  description = "Select to enable storing alb logs in s3 bucket."
  default     = false
}

variable "create_ecr" {
  type    = bool
  default = false
}

variable "ecr_access_for_account_id" {
  type    = string
  default = ""
}

variable "create_deployment_user" {
  type    = bool
  default = false
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
