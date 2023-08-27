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

variable "alias_domain_name" {
  description = "While domain_name usually defines internal domain names, the alias domain repesents a second domain which is used as primary."
  type        = string
  default     = ""
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

variable "disable_custom_error_response" {
  type        = bool
  default     = false
  description = "Needs to be enabled in cases where API responses are masked by a custom error response on 404."
}

variable "enable_s3_for_static_website" {
  description = "Creates an AWS S3 bucket and serve static webpages from it."
  type        = bool
  default     = true
}

variable "s3_static_website_bucket_cf_function_arn" {
  type        = string
  description = "String that defines cloudfront function for static website bucket."
  default     = ""
}

variable "s3_solution_bucket_cf_behaviours" {
  type        = list(any)
  description = "Option that exposes S3 solution bucket via Cloudfront with different behaviours."
  default     = []
}

variable "s3_solution_bucket_name" {
  type        = string
  description = "S3 solution bucket's name."
  default     = ""
}

variable "s3_solution_bucket_arn" {
  type        = string
  description = "S3 solution bucket's arn."
  default     = ""
}

variable "s3_solution_bucket_domain_name" {
  type        = string
  description = "S3 solution bucket's domain name."
  default     = ""
}
