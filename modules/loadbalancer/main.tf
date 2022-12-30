# ---------------------------------------------------------------------------------------------------------------------
# Application Loadbalancer
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-elb-alb-not-public
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_lb" "this" {
  name               = "${var.solution_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = var.security_groups

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.lb-logs.bucket
    prefix  = "${var.solution_name}-alb"
    enabled = true
  }
}

# tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "lb-logs" {
  bucket = "${var.solution_name}-alb-logs-s3-bucket-${random_string.random_s3_alb_logs_postfix.result}"
}
# ---------------------------------------------------------------------------------------------------------------------
# Block public access per-se
# TF: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.lb-logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption_config" {
  bucket = aws_s3_bucket.lb-logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "lb-logs-acl" {
  bucket = aws_s3_bucket.lb-logs.id
  acl    = "private"
}

data "aws_iam_policy_document" "allow-lb" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elb.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.lb-logs.arn}/*"
    ]
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = ["054676820928"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.lb-logs.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "allow-lb" {
  bucket = aws_s3_bucket.lb-logs.id
  policy = data.aws_iam_policy_document.allow-lb.json
}

resource "random_string" "random_s3_alb_logs_postfix" {
  length    = 4
  special   = false
  min_lower = 4
}

resource "aws_ssm_parameter" "environment_alb_arn" {
  name  = "/${var.solution_name}/alb_arn"
  type  = "String"
  value = aws_lb.this.arn
}

resource "aws_ssm_parameter" "environment_alb_url" {
  name  = "/${var.solution_name}/alb_url"
  type  = "String"
  value = aws_lb.this.dns_name
}
