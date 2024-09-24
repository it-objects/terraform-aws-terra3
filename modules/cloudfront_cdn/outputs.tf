output "cloudfront_domain_name" {
  value = try(aws_cloudfront_distribution.general_distribution[0].domain_name, "")
}

output "cloudfront_arn" {
  value = try(aws_cloudfront_distribution.general_distribution[0].arn, "")
}

output "s3_static_website_arn" {
  value = try(aws_s3_bucket.s3_static_website[0].arn, "")
}

output "s3_static_website_bucket" {
  value = try(aws_s3_bucket.s3_static_website[0].bucket, "")
}
