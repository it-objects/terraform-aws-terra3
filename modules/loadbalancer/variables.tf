variable "solution_name" {
  type = string
}

variable "public_subnets" {
  default     = []
  type        = list(string)
  description = "List of public subnet ids."
}

variable "security_groups" {
  default     = []
  type        = list(string)
  description = "List of security group ids."
}
