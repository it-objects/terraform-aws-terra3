# -----------------------------------------------
# Internal Service DNS Module - Variables
# -----------------------------------------------

variable "enable" {
  description = "Enable internal service DNS zone creation"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID where the internal zone will be deployed"
  type        = string
}

variable "solution_name" {
  description = "Solution name for resource naming"
  type        = string

  validation {
    condition     = length(var.solution_name) <= 16 && can(regex("^([a-z0-9])+(?:-[a-z0-9]+)*$", var.solution_name))
    error_message = "Only max. 16 lower-case alphanumeric characters and dashes in between are allowed."
  }
}

variable "zone_name" {
  description = "Custom zone name (defaults to internal.{solution_name}.local)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
