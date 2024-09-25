variable "addOidcUrlToIamInfraRoleMapping" {
  description = "Mapping of OIDC provider URLs to the IAM role paths specifically for infrastructure roles."
  type        = map(string)
  default     = {}
}

variable "addOidcUrlToIamECRRoleMapping" {
  description = "Mapping of OIDC provider URLs to the IAM roles and associated ECR names. Each entry contains the project path and the corresponding ECR name."
  type        = any
  default     = {}
}
variable "addOidcUrlToIamS3StaticWebsiteRoleMapping" {
  description = "Mapping of OIDC provider URLs to the IAM roles, S3 bucket names, and CloudFront ARNs. Each entry contains the project path, S3 bucket name, and CloudFront ARN."
  type        = any
  default     = {}
}
