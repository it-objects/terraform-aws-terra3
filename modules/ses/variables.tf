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
