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
}

variable "scheduled_api_apikey_key" {
  type        = string
  description = "apikey key as query param."
}

variable "scheduled_api_apikey_value" {
  type        = string
  description = "apikey value as query param."
}
