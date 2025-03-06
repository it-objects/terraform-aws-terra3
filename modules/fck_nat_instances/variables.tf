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

variable "enable_fcknat_eip" {
  type        = bool
  default     = false
  description = "Whether to use elastic ip for FCK-NAT"
}

variable "public_subnets" {
  type = list(any)
}

variable "private_subnets" {
  type = list(any)
}

variable "private_subnets_cidr_blocks" {
  default     = []
  type        = list(string)
  description = "List of cidr_blocks of private subnets"
}

variable "fcknat_instance_type" {
  default     = ["t4g.nano"]
  type        = list(string)
  description = "Enter the instance type."
}

variable "fcknat_use_spot_instance" {
  type        = bool
  default     = false
  description = "Whether to use spot instances for FCK-NAT"
}

variable "extra_security_groups" {
  default     = []
  type        = list(string)
  description = "Extra security groups to attach to nat instances"
}

variable "tags" {
  description = "Tags to apply to resources created within the module"
  type        = map(string)
  default = {
    fck-nat = true
  }
}
