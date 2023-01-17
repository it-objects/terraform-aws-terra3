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

variable "enable_alb_logs" {
  type        = bool
  description = "Select to enable storing alb logs in s3 bucket."
  default     = false
}

variable "enable_custom_domain" {
  description = "Indicates whether to use a custom domain or the AWS default domains for CloudFront and ALB."
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = ""
  type        = string
}

variable "domain_name" {
  description = ""
  type        = string
}
