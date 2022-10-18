variable "name" {
  type = string
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "The vpc id that Rancher should use"
}

variable "create_dns_and_certificates" {
  type    = bool
  default = false
}
