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
  description = "Select NO_NAT for no NAT, NAT_INSTANCES for NAT based on EC2 instances, ALTER_NAT for hourly based EC2 instances or NAT_GATEWAY for NAT with AWS NAT Gateways."
  type        = string
  default     = "NO_NAT"

  validation {
    condition     = contains(["NAT_INSTANCES", "NO_NAT", "ALTER_NAT", "NAT_GATEWAY_PER_SUBNET", "NAT_GATEWAY_SINGLE", "NAT_GATEWAY_PER_AZ"], var.nat)
    error_message = "Only 'NO_NAT', 'NAT_INSTANCES', 'ALTER_NAT', 'NAT_GATEWAY_PER_SUBNET', 'NAT_GATEWAY_SINGLE' and 'NAT_GATEWAY_PER_AZ' are allowed."
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

variable "public_subnets_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.32.0/20", "172.72.48.0/20"]
}

variable "private_subnets_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.0.0/20", "172.72.16.0/20"]
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

variable "create_s3_bucket" {
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

variable "ingress_security_group_ids" {
  description = "A list of security group IDs that are allowed by the NAT instance."
  type        = list(string)
  default     = []
}

variable "nat_subnet_suffix" {
  description = "Suffix in the NAT private subnet name to search for when updating routes via HA NAT Lambda functions."
  type        = string
  default     = "private"
}

variable "tags" {
  description = "A map of tags to add to all supported resources managed by the module."
  type        = map(string)
  default     = {}
}
