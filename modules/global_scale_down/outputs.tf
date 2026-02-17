output "s3_admin_website_url" {
  value       = try(aws_s3_bucket.bucket[0].bucket_regional_domain_name, "")
  description = "URL of S3 mini admin website bucket."
}

output "scale_up_lambda_function_url" {
  value       = try(aws_lambda_function_url.scale_up_lambda_function_url[0].function_url, "")
  description = "Lambda Function URL for scale up."
}

output "scale_down_lambda_function_url" {
  value       = try(aws_lambda_function_url.scale_down_lambda_function_url[0].function_url, "")
  description = "Lambda Function URL for scale down."
}

output "status_lambda_function_url" {
  value       = try(aws_lambda_function_url.status_lambda_function_url[0].function_url, "")
  description = "Lambda Function URL for status."
}
