variable "azs" {
  type        = list(string)
  description = ""
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "cidr" {
  type        = string
  description = ""
  default     = "172.72.0.0/16"
}

variable "private_subnets_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.0.0/24", "172.72.1.0/24"]
}

variable "public_subnets_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.2.0/24", "172.72.3.0/24"]
}

variable "database_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.4.0/24", "172.72.5.0/24"]
}

variable "elasticache_cidr_blocks" {
  type        = list(string)
  description = ""
  default     = ["172.72.6.0/24", "172.72.7.0/24"]
}

variable "use_an_existing_vpc" {
  description = "Enables/disables an AWS Application Load Balancer."
  type        = bool
  default     = false
}
