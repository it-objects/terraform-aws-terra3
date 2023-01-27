variable "name" {
  type        = string
  description = "Name of container."
}

variable "container_image" {
  type        = string
  description = "Reference of container image, e.g. 'nginx:1.23.1'"
}

variable "container_cpu" {
  type = number
}

variable "container_memory" {
  type = number
}

variable "container_memory_reservation" {
  type    = number
  default = null
}

variable "port_mappings" {
  type = list(object({
    containerPort = number
    protocol      = string
  }))

  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"

  default = []
}

variable "map_environment" {
  type        = map(string)
  description = "The environment variables to pass to the container. This is a map of string: {key: value}. map_environment overrides environment"
  default     = null
}

variable "environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container. This is a list of maps. map_environment overrides environment"
  default     = []
}

variable "map_secrets" {
  type        = map(string)
  description = "The secret references to pass to the container. This is a map of string: {key: value}. map_secrets overrides environment"
  default     = null
}

variable "secrets" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The secret references to pass to the container. This is a list of maps. map_secrets overrides environment"
  default     = []
}

variable "essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = true
}

variable "command" {
  type        = list(string)
  description = "Overwrites command from Dockerfile."
  default     = null
}

variable "readonlyRootFilesystem" {
  type        = bool
  description = "Best practice is to enable it, but causes issues in some cases."
  default     = false
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable "log_configuration" {
  type        = any
  description = "Log configuration options to send to a custom log driver for the container."
  default     = null
}

variable "enable_firelens_container" {
  description = "Select true to enable firelens container."
  type        = bool
  default     = false
}
