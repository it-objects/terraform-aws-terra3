variable "solution_name" {
  type = string
}

variable "file_name" {
  type        = string
  description = "String that defines Viewer Response Function type of Lamnda@Edge for static website bucket."
  default     = "origin_request"
}

variable "source_path" {
  type        = string
  description = "String that defines Origin Response Function type of Lamnda@Edge for static website bucket."
  default     = "/lambda_at_edge/"
}

variable "enable_spa" {
  type        = bool
  default     = false
  description = "Enable Viewer Request Function type of Lamnda@Edge for static website bucket."
}
