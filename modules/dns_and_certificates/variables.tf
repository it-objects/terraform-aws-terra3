variable "solution_name" {
  type = string
}

variable "route53_subdomain" {
  type        = string
  description = "subdomain name."
}

variable "route53_zone_id" {
  type        = string
  description = "Put in here the zone id of the Hosted Zone to which the subdomain should be added"
}

variable "domain" {
  type        = string
  description = "Domain of hosted zone."
}

variable "create_load_balancer" {
  type        = bool
  default     = false
  description = "Enables/disables an AWS Application Load Balancer."
}

variable "lb_dns_name" {
  description = "Loadbalancer DNS name to create a CNAME for"
  type        = string
  default     = ""
}

variable "alias_domain_name" {
  description = "Alias domain"
  type        = string
  default     = ""
}

variable "alias_domain_name_2" {
  description = "Alias domain 2"
  type        = string
  default     = ""
}
