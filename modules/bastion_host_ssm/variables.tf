variable "solution_name" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnets of vpc."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the bastion host. Override when a use case requires a different instance type than the default t4g.nano."
  default     = "t4g.nano"
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags to apply to the bastion host ASG and its instances."
  default     = {}
}
