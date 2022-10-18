data "aws_cloudfront_cache_policy" "ManagedCachingDisabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "ManagedAllViewer" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_origin_request_policy" "ManagedCORSS3Origin" {
  name = "Managed-CORS-S3Origin"
}

# ---------------------------------------------------------------------------------------------------------------------
# Canonical user ID for the effective account in which Terraform is working.
# ---------------------------------------------------------------------------------------------------------------------
data "aws_canonical_user_id" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# CloudFront Log Delivery Canonical User ID
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_log_delivery_canonical_user_id
# ---------------------------------------------------------------------------------------------------------------------
data "aws_cloudfront_log_delivery_canonical_user_id" "current" {}
