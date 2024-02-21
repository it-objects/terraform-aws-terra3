output "lambda_at_edge_arn" {
  value = aws_lambda_function.lambda_at_edge.arn
}

output "lambda_at_edge_version" {
  value = aws_lambda_function.lambda_at_edge.version
}
