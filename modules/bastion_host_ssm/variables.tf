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

# -----------------------------------------------
# AMI Update Automation
# -----------------------------------------------

variable "enable_ami_updates" {
  description = "Enable automated AMI updates via EventBridge + Lambda. Periodically checks for newer AMIs, updates the launch template, and triggers an instance refresh."
  type        = bool
  default     = false
}

variable "ami_update_schedule" {
  description = "EventBridge schedule expression for AMI update checks (e.g., 'rate(7 days)' or 'cron(0 3 ? * SUN *)')"
  type        = string
  default     = "rate(7 days)"
}

variable "ami_update_sns_topic_arn" {
  description = "Optional SNS topic ARN for AMI update notifications. If empty, no notifications are sent."
  type        = string
  default     = ""
}
