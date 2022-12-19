variable "environment" {
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

variable "total_cpu" {
  type = number
}

variable "total_memory" {
  type = number
}

variable "container" {
  type = list(object({
    name             = string
    container_image  = string
    container_cpu    = number
    container_memory = number
    port_mappings = list(object({
      containerPort = number
      protocol      = string
    }))
    environment = list(object({
      name  = string
      value = string
    }))
    essential              = bool
    readonlyRootFilesystem = bool
  }))
}

variable "lb_domain_name" {
  description = "Domain name of loadbalancer if set."
  default     = ""
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
  description = "Enable automatic scaling and cycle down overnight e.g. for cost savings in QA."
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
  default     = "cron(0 8 ? * MON-FRI *)" # Every weekday at 7:00 CET
  description = ""
}

variable "autoscale_down_event" {
  type        = string
  default     = "cron(0 17 ? * * *)" # Every day send a scaledown at 19:00 CET
  description = ""
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
