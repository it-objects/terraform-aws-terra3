output "s3_bucket_domain_name" {
  value = aws_s3_bucket.s3_data_bucket.bucket_domain_name
}

output "s3_solution_bucket_name" {
  value = aws_s3_bucket.s3_data_bucket.id
}

output "s3_bucket_policy_json" {
  value = data.aws_iam_policy_document.s3_data_bucket_policy.json
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.s3_data_bucket.arn
}

output "ssm_parameter_s3_bucket_arn" {
  value = aws_ssm_parameter.s3_solution_bucket.arn
}
