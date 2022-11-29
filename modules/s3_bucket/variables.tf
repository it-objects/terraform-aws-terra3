variable "solution_name" {
  type = string
}

variable "s3_bucket_policy" {
  type        = string
  description = "Type of database."
  default     = "PRIVATE"

  validation {
    condition     = contains(["PRIVATE", "PUBLIC_READ_ONLY"], var.s3_bucket_policy)
    error_message = "Only 'PRIVATE' and 'PUBLIC_READ_ONLY' are allowed."
  }
}
