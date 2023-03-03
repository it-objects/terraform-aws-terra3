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

variable "cpu_utilization_alert" {
  description = "Select true to get alert based on CPU Utilisation"
  type        = bool
  default     = false
}

variable "memory_utilization_alert" {
  description = "Select true to get alert based on MEMORY Utilisation"
  type        = bool
  default     = false
}

variable "cpu_utilization_high_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "cpu_utilization_high_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "cpu_utilization_high_threshold" {
  type        = number
  description = "The maximum percentage of CPU utilization average"
  default     = 90
}

variable "cpu_utilization_low_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "cpu_utilization_low_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "cpu_utilization_low_threshold" {
  type        = number
  description = "The minimum percentage of CPU utilization average"
  default     = 30
}

variable "memory_utilization_high_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "memory_utilization_high_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "memory_utilization_high_threshold" {
  type        = number
  description = "The maximum percentage of Memory utilization average"
  default     = 90
}

variable "memory_utilization_low_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "memory_utilization_low_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "memory_utilization_low_threshold" {
  type        = number
  description = "The minimum percentage of Memory utilization average"
  default     = 20
}

variable "sns_topic_arn" {
  type        = set(string)
  description = ""
  default     = []
}

variable "alert_receivers_email" {
  type        = list(string)
  default     = []
  description = "Email address for the endpoint of SNS subscription."
}

variable "task_count_alert" {
  description = "Select true to get alert based on ecs running task"
  type        = bool
  default     = false
}

variable "task_count_threshold" {
  type        = number
  description = "The minimum running ecs tasks."
  default     = 1
}

variable "task_count_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "task_count_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "create_load_balancer" {
  description = "Enables/disables an AWS Application Load Balancer."
  type        = bool
  default     = false
}

variable "enable_alb_logs" {
  type        = bool
  description = "Select to enable storing alb logs in s3 bucket."
  default     = false
}

variable "enable_custom_domain" {
  description = "Creates DNS entries and ACM certificates to be consumed by other resources."
  type        = bool
  default     = false
}

variable "default_redirect_url" {
  description = "In case a URL cannot be matched by the LB, the request should be redirected to this URL."
  type        = string
  default     = "terra3.io"
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

variable "create_subdomain" {
  type        = bool
  description = "Creates either a subdomain using the solution_name or uses the hosted zone's domain."
  default     = true
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

variable "database_allocated_storage" {
  description = "allocated_storage"
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "max_allocated_storage"
  type        = number
  default     = 20
}

variable "database_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "database_deletion_protection" {
  description = "If the cluster should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "database_multi_az" {
  description = "Multi Availability Zones"
  type        = bool
  default     = false
}

variable "database_instance_instance_class" {
  description = "Database instance type"
  type        = string
  default     = "db.t3.small"
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

variable "s3_static_website_bucket_cf_function_arn" {
  type        = string
  description = "String that defines cloudfront function for static website bucket."
  default     = ""
}

variable "disable_custom_error_response" {
  type        = bool
  default     = false
  description = "Needs to be enabled in cases where API responses are masked by a custom error response on 404."
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
  description = "Select FARGATE for cluster type as FARGATE, or Select FARGATE_SPOT for cluster type as FARGATE_SPOT or select EC2 for cluster type as EC2."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "EC2"], var.cluster_type)
    error_message = "Only 'FARGATE', 'FARGATE_SPOT' and 'EC2' are allowed."
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

variable "create_ecr" {
  type    = bool
  default = false
}

variable "ecr_custom_name" {
  description = "Custom name for ECR repo. Otherwise, solution name is taken."
  type        = string
  default     = ""
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

variable "create_ses" {
  type        = bool
  description = "Enable it to use AWS simple email service."
  default     = false
}

variable "ses_domain_name" {
  type        = string
  description = "Define domain name to be verified."
  default     = ""
}

variable "ses_mail_from_domain" {
  description = "Define mail from domain name. Usually the same as the ses_domain_name."
  type        = string
  default     = ""
}

variable "set_cluster_name_for_k8s_subnet_tagging" {
  description = "Enables/disables proper tagging for subnet discovery in case of using K8s and AWS ELB."
  type        = string
  default     = ""
}

variable "use_an_existing_vpc" {
  description = "Enables/disables an AWS Application Load Balancer."
  type        = bool
  default     = false
}

variable "external_vpc_id" {
  type        = string
  description = "vpc id of existing vpc."
  default     = ""
}

variable "external_public_subnets" {
  type        = list(string)
  description = "Public subnets of existing vpc."
  default     = []
}

variable "external_private_subnets" {
  type        = list(string)
  description = "Private subnets of existing vpc."
  default     = []
}

variable "external_vpc_private_route_table_ids" {
  type        = list(string)
  description = "Private route table ids of existing vpc."
  default     = []
}

variable "external_db_subnet_group_name" {
  type        = string
  description = "Database subnet group name of existing vpc."
  default     = ""
}

variable "external_elasticache_subnet_ids" {
  type        = list(string)
  description = "Elasticache subnet ids of existing vpc."
  default     = []
}

variable "enable_scheduled_https_api_call" {
  type        = bool
  description = "Select true to enable scheduled api call."
  default     = false
}

variable "scheduled_https_api_call_crontab" {
  type        = string
  description = "Enter schedule details of scheduled api call in crontab format."
  default     = ""
}

variable "scheduled_https_api_call_url" {
  type        = string
  description = "Enter url of scheduled api call."
  default     = ""
}

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
