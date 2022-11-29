variable "solution_name" {
  type = string
}

variable "origin_alb_url" {
  type    = string
  default = ""
}

variable "domain" {
  type        = string
  description = "DNS configuration: Domain name. E.g. aws-sandbox.terra3.io"
}

variable "certificate_arn" {
  type        = string
  description = "Certificate for cloudfront residing in Virginia."
  default     = ""
}

variable "calculated_zone_id" {
  type        = string
  default     = ""
  description = "Put in here the zone id of the Hosted Zone to which the subdomain should be added."
}

variable "add_default_index_html" {
  type    = bool
  default = true
}

variable "enable_s3_for_static_website" {
  description = "Creates an AWS S3 bucket and serve static webpages from it."
  type        = bool
  default     = true
}

variable "app_components" {
  description = "Define here the app_component object. See the examples or documentation for more details."
  type        = any
  default     = {}
}
