variable "app_name" {
  type = string
}

variable "oidc_gitlab_arn" {
  type = string
}

variable "oidc_gitlab_url" {
  type = string
}

variable "match_field" {
  type    = string
  default = "sub"
}

variable "match_value" {
  type = list(any)
}

variable "policy_statements" {
  type = any
}
