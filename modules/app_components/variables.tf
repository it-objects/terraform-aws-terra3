variable "app_components" {
  description = "Define here the app_component object. See the examples or documentation for more details."
  type        = any
  default     = {}
}

variable "solution_name" {
  type        = string
  description = "Reference to name of environment."
}

variable "cpu_utilization_alert" {
  description = "Select true to get alert based on CPU Utilisation"
  type        = bool
  default     = false
}

variable "memory_utilization_alert" {
  description = "Select true to get alert based on MEMORY Utilisation"
  type        = bool
  default     = false
}

variable "cpu_utilization_high_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "cpu_utilization_high_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "cpu_utilization_high_threshold" {
  type        = number
  description = "The maximum percentage of CPU utilization average"
  default     = 90
}

variable "cpu_utilization_low_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "cpu_utilization_low_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "cpu_utilization_low_threshold" {
  type        = number
  description = "The minimum percentage of CPU utilization average"
  default     = 30
}

variable "memory_utilization_high_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "memory_utilization_high_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "memory_utilization_high_threshold" {
  type        = number
  description = "The maximum percentage of Memory utilization average"
  default     = 90
}

variable "memory_utilization_low_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "memory_utilization_low_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "memory_utilization_low_threshold" {
  type        = number
  description = "The minimum percentage of Memory utilization average"
  default     = 20
}

variable "sns_topic_arn" {
  type        = set(string)
  description = ""
  default     = []
}

variable "alert_receivers_email" {
  type        = list(string)
  default     = []
  description = "Email address for the endpoint of SNS subscription."
}

variable "task_count_alert" {
  description = "Select true to get alert based on ecs running task"
  type        = bool
  default     = false
}

variable "task_count_threshold" {
  type        = number
  description = "The minimum running ecs tasks."
  default     = 1
}

variable "task_count_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 3
}

variable "task_count_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 300
}

variable "enable_container_insights" {
  description = "Enables/disables more detailed logging via Container Insights for ECS."
  type        = bool
  default     = false
}

variable "two_states_approach" {
  type        = bool
  default     = true
  description = "Internal variable that indicates whether this is internally or externally called."
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}


variable "enable_ecs_autoscaling" {
  description = "Enables/disables auto-scaling cpu utilisation and memory utilisation of ECS."
  type        = bool
  default     = false
}

variable "ecs_autoscaling_metric_type" {
  description = "Select CPU_UTILISATION to perform auto scaling based on CPU Utilisation, or select MEMORY_UTILISATION for MEMORY Utilisation."
  type        = string
  default     = "CPU_UTILISATION"

  validation {
    condition     = contains(["CPU_UTILISATION", "MEMORY_UTILISATION"], var.ecs_autoscaling_metric_type)
    error_message = "Only 'CPU_UTILISATION', and 'MEMORY_UTILISATION' are allowed."
  }
}

variable "ecs_autoscaling_max_capacity" {
  description = "Select the maximum nodes for ecs."
  type        = number
  default     = 2
}

variable "ecs_autoscaling_min_capacity" {
  description = "Select the minimum nodes for ecs."
  type        = number
  default     = 1
}

variable "ecs_autoscaling_target_value" {
  description = "Select the target value for ecs."
  type        = number
  default     = 80
}
