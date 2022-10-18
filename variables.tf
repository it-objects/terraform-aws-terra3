variable "solution_name" {
  type        = string
  description = "Update your solution name here; max. 8 lower-case characters."
}

variable "app_components" {
  type    = any
  default = {}
}

variable "enable_account_best_practices" {
  type    = bool
  default = false
}

variable "nat" {
  type    = string
  default = "NO_NAT"

  validation {
    condition     = contains(["NAT_INSTANCES", "NO_NAT", "NAT_GATEWAY"], var.nat)
    error_message = "Only 'NAT_INSTANCES','NO_NAT' and 'NAT_GATEWAY' are allowed."
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

variable "add_default_index_html" {
  type    = bool
  default = true
}

variable "route53_zone_id" {
  type        = string
  description = "Put in here the zone id of the Hosted Zone to which the subdomain should be added"
  default     = ""
}

variable "single_az_setup" {
  type        = bool
  description = "Multi-AZ is default."
  default     = false
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

variable "enable_ecs_exec" {
  description = "Required for ECS exec. Either the key given by its id here is used or a new one is created."
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enables/disables more detailed logging via container insights for ECS."
  type        = bool
  default     = false
}
