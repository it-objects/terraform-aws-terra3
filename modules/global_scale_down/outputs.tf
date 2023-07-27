output "s3_admin_website_url" {
  value       = try(aws_s3_bucket.bucket[0].bucket_regional_domain_name, "")
  description = "URL of S3 mini admin website bucket."
}
