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
