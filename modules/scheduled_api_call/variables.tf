variable "enable_eventbridge_scheduled_Api_call" {
  type        = bool
  description = "Select true to enable eventbridge scheduled api call."
  default     = false
}

variable "solution_name" {
  type = string
}

variable "scheduled_api_call_cron" {
  type        = string
  default     = "rate(60 minutes)"
  description = "Cron tab."
}

variable "scheduled_api_call_http_method" {
  type        = string
  default     = "POST"
  description = "HTTP method."
}

variable "scheduled_api_call_url" {
  type        = string
  description = "URL to be triggered."
  default     = ""
}

variable "scheduled_api_apikey_key" {
  type        = string
  description = "apikey key as query param."
  default     = ""
}

variable "scheduled_api_apikey_value" {
  type        = string
  description = "apikey value as query param."
  default     = ""
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
