variable "solution_name" {
  type = string
}

variable "file_name" {
  type        = string
  description = "String that defines Viewer Response Function type of Lamnda@Edge for static website bucket."
  default     = "origin_request"
}
