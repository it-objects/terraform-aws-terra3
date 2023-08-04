variable "ecr_name" {
  type = string
}

variable "access_for_account_id" {
  type    = string
  default = ""
}

variable "access_for_account_ids" {
  type    = list(string)
  default = [""]
}
