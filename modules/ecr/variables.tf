variable "ecr_name" {
  type = string
}

variable "create_ecr_with_names" {
  type    = list(string)
  default = []
}

variable "access_for_account_id" {
  description = "The AWS account ID for which access permissions will be configured to Amazon ECR repositories."
  type        = string
  default     = ""
}

variable "access_for_account_ids" {
  description = "The AWS account IDs for which access permissions will be configured to Amazon ECR repositories."
  type        = list(string)
  default     = []
}
