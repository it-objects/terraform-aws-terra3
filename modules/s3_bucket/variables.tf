variable "solution_name" {
  type = string
}

variable "s3_solution_bucket_enable_acl" {
  type        = bool
  description = "Option that overwrites more secure ACL-less S3 buckets. Please note, that enabling ACL comes with certain security considerations"
  default     = false
}
