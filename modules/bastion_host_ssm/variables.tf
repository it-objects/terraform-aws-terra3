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
  description = "EC2 instance type for the bastion host. Must have sufficient RAM for any agents installed (e.g. t4g.micro for Microsoft Defender)."
  default     = "t4g.nano"
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags to apply to the bastion host ASG and its instances."
  default     = {}
}
