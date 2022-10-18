variable "enable_account_wide_block_public_s3_access" {
  type        = bool
  default     = true
  description = "By default all S3 buckets have public access blocked."
}

variable "enable_account_wide_ebs_encryption" {
  type        = bool
  default     = true
  description = "By default all EBS volumes are encrypted."
}
