variable "ses_domain_name" {
  type        = string
  description = "Domain that emails are sent from"
  default     = ""
}

variable "mail_from_domain" {
  type    = string
  default = ""
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

variable "create_ses_user" {
  type        = bool
  default     = true
  description = "Creates IAM user along SES creation. Should be disabled in case of restrictive SCPs that deny access to IAM."
}
