variable "solution_name" {
  type = string
}

variable "enable_scheduled_https_api_call" {
  type        = bool
  description = "Select true to enable scheduled api call."
  default     = false
}

variable "scheduled_https_api_call_crontab" {
  type        = string
  description = "Enter schedule details of scheduled api call in crontab format."
  default     = ""
}

variable "scheduled_https_api_call_url" {
  type        = string
  description = "Enter url of scheduled api call."
  default     = ""
}
