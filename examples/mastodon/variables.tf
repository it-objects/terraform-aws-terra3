variable "solution_name" {
  type        = string
  description = "Update your solution name here; max. 8 lower-case characters."
}

variable "mastodon_image" {
  type        = string
  description = "Pointer to official Mastodon image + image tag."
  default     = "tootsuite/mastodon:v4.1.7"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 zone id of AWS Hosted Zone to which access rights exists or which you have created upfront."
}

variable "secret_key_base" {
  type        = string
  description = "Generate with rake secret. Changing it will break all active browser sessions."
}

variable "otp_secret" {
  type        = string
  description = "Generate with rake secret. Changing it will break two-factor authentication."
}

variable "vapid_private_key" {
  type        = string
  description = "Generate with rake mastodon:webpush:generate_vapid_key. Changing it will break push notifications."
}

variable "vapid_public_key" {
  type        = string
  description = "Generate with rake mastodon:webpush:generate_vapid_key. Changing it will break push notifications."
}

variable "smtp_server" {
  type = string
}

variable "smtp_login" {
  type = string
}

variable "smtp_password" {
  type = string
}

variable "smtp_from_address" {
  type = string
}
