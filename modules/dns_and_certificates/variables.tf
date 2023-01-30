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

variable "create_subdomain" {
  type        = bool
  description = "Creates either a subdomain using the solution_name or uses the hosted zone's domain."
  default     = true
}

variable "domain" {
  type        = string
  description = "Domain of hosted zone."
}

variable "create_load_balancer" {
  type        = bool
  description = "Indicates whether load balancer has been created."
  default     = false
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
