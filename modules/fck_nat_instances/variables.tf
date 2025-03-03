variable "solution_name" {
  type = string
}

variable "azs" {
  default     = null
  type        = list(string)
  description = "List of AWS Availability Zones in the VPC"
}

variable "vpc_id" {
  description = "VPC ID to deploy the NAT instance into"
  type        = string
}

variable "update_route_table" {
  description = "Deprecated. Use update_route_tables instead"
  type        = bool
  default     = false
}

variable "update_route_tables" {
  description = "Whether or not to update the route tables with the NAT instance"
  type        = bool
  default     = false
}

variable "route_table_id" {
  description = "Deprecated. Use route_tables_ids instead"
  type        = string
  default     = null
}

variable "route_tables_ids" {
  description = "Route tables to update. Only valid if update_route_tables is true"
  type        = map(string)
  default     = {}
}

variable "ha_mode" {
  description = "Whether or not high-availability mode should be enabled via autoscaling group"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "Instance type to use for the NAT instance"
  type        = list(string)
  default     = ["t4g.micro"]
}

variable "ami_id" {
  description = "AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided"
  type        = string
  default     = null
}

variable "eip_allocation_ids" {
  description = "EIP allocation IDs to use for the NAT instance. Automatically assign a public IP if none is provided. Note: Currently only supports at most one EIP allocation."
  type        = list(string)
  default     = []
}

variable "use_spot_instances" {
  description = "Whether or not to use spot instances for running the NAT instance"
  type        = bool
  default     = false
}

variable "use_ssh" {
  description = "Whether or not to enable SSH access to the NAT instance"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks to allow SSH access to the NAT instance from"
  type = object({
    ipv4 = optional(list(string), [])
    ipv6 = optional(list(string), [])
  })
  default = {
    ipv4 = [],
    ipv6 = []
  }
}

variable "tags" {
  description = "Tags to apply to resources created within the module"
  type        = map(string)
  default = {
    fck-nat = true
  }
}








variable "public_subnets" {
  type = list(any)
}

variable "private_subnets" {
  type = list(any)
}

variable "private_route_table_ids" {
  type = list(any)
}

variable "private_subnets_cidr_blocks" {
  default     = []
  type        = list(string)
  description = "List of cidr_blocks of private subnets"
}

variable "public_subnets_cidr_blocks" {
  default     = []
  type        = list(string)
  description = "List of cidr_blocks of public subnets"
}

variable "nat_instance_types" {
  default     = ["t4g.nano"]
  type        = list(string)
  description = "Defaulting to free tier EC2 instance."
}

variable "extra_security_groups" {
  default     = []
  type        = list(string)
  description = "Extra security groups to attach to nat instances"
}

variable "nat_use_spot_instance" {
  type        = bool
  default     = false
  description = "Whether to use spot instances for NAT"
}
