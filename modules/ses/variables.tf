variable "aws_region" {
  description = "Region where the S3 bucket is deployed."
  type        = string
  default     = "eu-central-1"
}

variable "hosted_zone_domain" {
  description = "Route 53 Hosted Zone domain"
  type        = string
  default     = "aws-sandbox.it-objects.de"
}

variable "domain" {
  description = "Domain that emails are sent from"
  type        = string
  default     = "info.aws-sandbox.it-objects.de"
}

variable "name" {
  type        = string
  description = "Name for created resources"
  default     = "ses-smtp"
}

variable "create_ses" {
  type        = bool
  default     = false
  description = "Enable it to use amazon simple email service"
}
