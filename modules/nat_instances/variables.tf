variable "solution_name" {
  type = string
}

variable "vpc_id" {
  type = string
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

variable "azs" {
  default     = null
  type        = list(string)
  description = "List of AWS Availability Zones in the VPC"
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
  default     = ["t2.micro"]
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
