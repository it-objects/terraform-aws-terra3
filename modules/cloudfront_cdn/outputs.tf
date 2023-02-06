output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.general_distribution.domain_name
}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.general_distribution.arn
}

output "s3_static_website_arn" {
  value = try(aws_s3_bucket.s3_static_website[0].arn, "")
}

output "s3_static_website_bucket" {
  value = try(aws_s3_bucket.s3_static_website[0].bucket, "")
}
