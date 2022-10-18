output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.general_distribution.domain_name
}

output "s3_static_website_arn" {
  value = aws_s3_bucket.s3_static_website.arn
}

output "s3_static_website_bucket" {
  value = aws_s3_bucket.s3_static_website.bucket
}
