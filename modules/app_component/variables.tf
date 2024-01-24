variable "solution_name" {
  type        = string
  description = "Reference to name of environment."
}

variable "container_runtime" {
  type        = string
  description = "Reference to name of container runtime the app module should run in."
}

variable "name" {
  type        = string
  description = "Name of application module."
}

variable "instances" {
  type        = number
  default     = 1
  description = "Horizontal scaling."
}

variable "cluster_type" {
  description = "Select FARGATE for cluster type as FARGATE, or Select FARGATE_SPOT for cluster type as FARGATE_SPOT or select EC2 for cluster type as EC2."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "EC2"], var.cluster_type)
    error_message = "Only 'FARGATE', 'FARGATE_SPOT' and 'EC2' are allowed."
  }
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

variable "total_cpu" {
  type = number
}

variable "total_memory" {
  type = number
}

# validation is ensured in container module
variable "container" {
  type = any
}

variable "enable_firelens_container" {
  description = "Select true to enable firelens container."
  type        = bool
  default     = false
}

#  CloudWatch alert based on cpu and memory utilization
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
  description = "The maximum percentage of CPU utilization average. Set to 0 to disable alarm."
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
  description = "The minimum percentage of CPU utilization average. Set to 0 to disable alarm."
  default     = 0
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
  description = "The maximum percentage of memory utilization average. Set to 0 to disable alarm."
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
  description = "The minimum percentage of memory utilization average. Set to 0 to disable alarm."
  default     = 0
}

variable "sns_topic_arn" {
  type        = set(string)
  description = "ARN of SNS topic"
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

# # IAM
variable "execution_iam_access" {
  description = "A complex object describing additional access beyond AmazonECSTaskExecutionRolePolicy needed to run"
  type        = map(list(string))
  default     = {}
}

variable "service_port" {
  type = number
}

variable "health_check_grace_period_seconds" {
  type    = number
  default = 0
}

variable "service_sg" {
  description = "Custom set of security groups"
  type        = list(any)
  default     = []
}

variable "enable_autoscaling" {
  description = "Enable automatic scaling and cycle down overnight e.g. for cost savings in QA. This use only this feature or enable_environment_hibernation_sleep_schedule feature at a time in order to avoid conflict."
  type        = bool
  default     = false
}

variable "autoscale_task_weekday_scale_down" {
  description = "Number of tasks at low periods."
  default     = 0
  type        = number
}

variable "autoscale_up_event" {
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
  description = "Default: Every weekday send a scaleup event at 8:00 TZ Europe/Berlin"
}

variable "autoscale_down_event" {
  type        = string
  default     = "cron(0 18 ? * * *)" #
  description = "Default: Every day send a scaledown event at 18:00 TZ Europe/Berlin"
}

variable "desired_count" {
  description = "Number of tasks to launch on weekdays"
  default     = 1
  type        = number
}

variable "enable_ecs_exec" {
  type        = bool
  default     = false
  description = "Enable ECS exec."
}

variable "configure_as_cronjob" {
  type        = string
  default     = ""
  description = "Doesn't create an ECS service but a task def only to be triggered by a step function."
}

variable "lb_healthcheck_url" {
  type        = string
  default     = "/"
  description = "loadbalancer health check url of target container"
}

variable "lb_healthcheck_port" {
  type        = number
  default     = 80
  description = "loadbalancer health check port of target container"
}

variable "listener_rule_prio" {
  type        = number
  description = "no priority number should be the same as any other."
}

variable "path_mapping" {
  type        = string
  description = "path mapping used in lb listener."
}

variable "default_redirect_url" {
  type        = string
  description = "In case a URL cannot be matched by the LB, the request should be redirected to this URL."
  default     = "terra3.io"
}

variable "deregistration_delay" {
  type        = number
  default     = 10
  description = "The time in seconds the loadbalancer waits until it removes the container from the target group."
}

variable "internal_service" {
  type        = bool
  default     = false
  description = "Set to true to don't attach service to loadbalancer and to keep it internal."
}

variable "s3_solution_bucket_access" {
  type        = bool
  default     = false
  description = "Gives component access to solution bucket."
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}
