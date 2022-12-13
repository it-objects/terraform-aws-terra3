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

#tfsec:ignore:aws-s3-specify-public-access-block
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-no-public-buckets
#tfsec:ignore:aws-s3-ignore-public-acls
#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-block-public-policy
#tfsec:ignore:aws-s3-block-public-acls
resource "aws_s3_bucket" "lb-logs" {
  bucket = "${var.solution_name}-alb-logs-s3-bucket-${random_string.random_s3_alb_logs_postfix.result}"
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
