variable "solution_name" {
  description = "Solution name for resource naming"
  type        = string
}

variable "name_suffix" {
  description = "Unique suffix to distinguish multiple instances of this module (e.g., 'bastion', 'docker-postgres')"
  type        = string
}

variable "launch_template_id" {
  description = "ID of the launch template to update with new AMI versions"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to trigger instance refresh on"
  type        = string
}

variable "ami_owners" {
  description = "List of AMI owner account IDs or aliases (e.g., ['amazon'])"
  type        = list(string)
  default     = ["amazon"]
}

variable "ami_name_filter" {
  description = "Name filter pattern for AMI lookup (e.g., 'al2023-ami-2023*')"
  type        = string
  default     = "al2023-ami-2023*"
}

variable "ami_architecture" {
  description = "CPU architecture filter for AMI lookup. Set to 'auto' to derive from the current launch template's AMI."
  type        = string
  default     = "auto"
}

variable "ami_additional_filters" {
  description = "Additional filters for AMI lookup as a map of filter name to values"
  type        = map(list(string))
  default = {
    "root-device-type"                 = ["ebs"]
    "virtualization-type"              = ["hvm"]
    "block-device-mapping.volume-type" = ["gp3"]
  }
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for AMI check (cron or rate)"
  type        = string
  default     = "rate(7 days)"
}

variable "min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh (0-100). For single-instance ASGs, use 0."
  type        = number
  default     = 0

  validation {
    condition     = var.min_healthy_percentage >= 0 && var.min_healthy_percentage <= 100
    error_message = "min_healthy_percentage must be between 0 and 100."
  }
}

variable "instance_warmup_seconds" {
  description = "Number of seconds to wait for a new instance to be ready before continuing the refresh"
  type        = number
  default     = 300
}

variable "sns_topic_arn" {
  description = "Optional SNS topic ARN for notifications on AMI updates. If empty, no notifications are sent."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
