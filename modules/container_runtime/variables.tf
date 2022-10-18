variable "container_runtime_name" {
  description = ""
  type        = string
}

variable "solution_kms_key_id" {
  description = "Required for ECS exec. Either the key given by its id here is used or a new one is created."
  type        = string
  default     = ""
}

variable "enable_ecs_exec" {
  description = "Required for ECS exec. Either the key given by its id here is used or a new one is created."
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enables/disables more detailed logging via container insights for ECS."
  type        = bool
  default     = false
}

variable "environment_name" {
  type = string
}
