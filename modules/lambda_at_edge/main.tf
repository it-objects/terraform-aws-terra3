data "archive_file" "lambda_at_edge" {
  type        = "zip"
  source_file = "${var.source_path}/${var.file_name}.mjs"
  output_path = "${var.source_path}/${var.file_name}.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "lambda_at_edge" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${var.source_path}/${var.file_name}.zip"
  function_name = "${var.solution_name}-${var.file_name}-cf-modify-response-header"
  description   = "lambda@edge function for the default error behaviour"

  role    = aws_iam_role.iam_for_lambda_at_edge.arn
  handler = "${var.file_name}.handler"
  publish = true
  runtime = "nodejs20.x"

  source_code_hash = data.archive_file.lambda_at_edge.output_base64sha256

  provider = aws.useast1
}

# IAM Policy Document
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "logs_for_lambda_at_edge" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      aws_cloudwatch_log_group.logs_for_lambda_at_edge.arn,
      "${aws_cloudwatch_log_group.logs_for_lambda_at_edge.arn}:*"
    ]
  }
}

# CloudWatch Log Group
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "logs_for_lambda_at_edge" {
  name = "/aws/lambda/${var.solution_name}-${var.file_name}-cf-modify-response-header"

  retention_in_days = 30

  tags = {
    Name = "${var.solution_name}-${var.file_name}-lambda-at-edge-LogGroup"
  }
}

# IAM Policy
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_iam_policy" "logs_for_lambda_at_edge" {
  name   = "${var.solution_name}-${var.file_name}-cf-modify-response-header-logs"
  policy = data.aws_iam_policy_document.logs_for_lambda_at_edge.json
}

# IAM Role
resource "aws_iam_role" "iam_for_lambda_at_edge" {
  name = "${var.solution_name}-${var.file_name}-cf-modify-response-header"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      },
    ]
  })
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "logs_for_lambda_at_edge" {
  role       = aws_iam_role.iam_for_lambda_at_edge.name
  policy_arn = aws_iam_policy.logs_for_lambda_at_edge.arn
}
