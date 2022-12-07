# ---------------------------------------------------------------------------------------------------------------------
# AWS S3 bucket
# TF: https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
# AWS: http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
# ---------------------------------------------------------------------------------------------------------------------
# tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "s3_data_bucket" {
  bucket = "${var.solution_name}-solution-s3-bucket-${random_string.random_s3_postfix.result}"
}

# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_enc_config" {
  bucket = aws_s3_bucket.s3_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.s3_data_bucket.id
  acl    = "private"
}

# ---------------------------------------------------------------------------------------------------------------------
# store s3-solution-bucket name in parameter store to be retrieved e.g. by application's API
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "s3_solution_bucket" {
  name  = "/${var.solution_name}/s3-solution-bucket"
  type  = "String"
  value = aws_s3_bucket.s3_data_bucket.bucket
}

resource "aws_ssm_parameter" "s3_solution_bucket_arn" {
  name  = "/${var.solution_name}/s3-solution-bucket-arn"
  type  = "String"
  value = aws_s3_bucket.s3_data_bucket.arn
}

resource "random_string" "random_s3_postfix" {
  length    = 4
  special   = false
  min_lower = 4
}

# ---------------------------------------------------------------------------------------------------------------------
# Block public access per-se
# TF: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.s3_data_bucket.bucket

  block_public_acls       = var.s3_solution_bucket_policy == "PUBLIC_READ_ONLY" ? false : true
  block_public_policy     = var.s3_solution_bucket_policy == "PUBLIC_READ_ONLY" ? false : true
  ignore_public_acls      = var.s3_solution_bucket_policy == "PUBLIC_READ_ONLY" ? false : true
  restrict_public_buckets = var.s3_solution_bucket_policy == "PUBLIC_READ_ONLY" ? false : true
}

# ---------------------------------------------------------------------------------------------------------------------
# [Data] IAM policy to define S3 permissions
# TF: https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_data_bucket_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_data_bucket.bucket}"
    ]
  }
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_data_bucket.bucket}/*"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS IAM policy
# TF: https://www.terraform.io/docs/providers/aws/r/iam_policy.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "s3_policy" {
  name   = "${var.solution_name}-s3-access-policy"
  policy = data.aws_iam_policy_document.s3_data_bucket_policy.json
}
