# -----------------------------------------------
# EC2 Docker Workload Module - IAM
# -----------------------------------------------

# -----------------------------------------------
# IAM Role for EC2 Instance
# -----------------------------------------------

resource "aws_iam_role" "docker_workload_role" {
  name = "${var.solution_name}-${var.instance_name}-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.solution_name}-${var.instance_name}-role"
    }
  )
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# -----------------------------------------------
# Instance Profile
# -----------------------------------------------

resource "aws_iam_instance_profile" "docker_workload_profile" {
  name = "${var.solution_name}-${var.instance_name}-profile"
  role = aws_iam_role.docker_workload_role.name
}

# -----------------------------------------------
# Base Policy: Systems Manager Access for debugging
# -----------------------------------------------

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.docker_workload_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------
# CloudWatch Logs Policy (always enabled)
# -----------------------------------------------

#tfsec:ignore:aws-iam-no-policy-wildcards # CloudWatch log group ARN requires :* for log stream operations
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.solution_name}-${var.instance_name}-cloudwatch-logs"
  role = aws_iam_role.docker_workload_role.id

  policy = data.aws_iam_policy_document.cloudwatch_logs.json

  depends_on = [aws_cloudwatch_log_group.docker_logs]
}

#tfsec:ignore:aws-iam-no-policy-wildcards # CloudWatch log group ARN requires :* for log stream operations
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.docker_logs.arn,
      "${aws_cloudwatch_log_group.docker_logs.arn}:*",
    ]
  }
}

# -----------------------------------------------
# ECR Access Policy (conditional)
# -----------------------------------------------

resource "aws_iam_role_policy" "ecr_access" {
  count = var.enable_ecr_access ? 1 : 0
  name  = "${var.solution_name}-${var.instance_name}-ecr-access"
  role  = aws_iam_role.docker_workload_role.id

  policy = data.aws_iam_policy_document.ecr_access[0].json
}

data "aws_iam_policy_document" "ecr_access" {
  count = var.enable_ecr_access ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = local.is_ecr_image ? [
      "arn:aws:ecr:${data.aws_region.current.id}:${var.ecr_source_account_id != "" ? var.ecr_source_account_id : data.aws_caller_identity.current.account_id}:repository/${local.ecr_repo_name}"
      ] : [
      "arn:aws:ecr:${data.aws_region.current.id}:${var.ecr_source_account_id != "" ? var.ecr_source_account_id : data.aws_caller_identity.current.account_id}:repository/*"
    ]
  }
}

# -----------------------------------------------
# EBS Volume Attachment Policy (for persistent volumes)
# -----------------------------------------------

resource "aws_iam_role_policy" "ebs_volume_attachment" {
  name = "${var.solution_name}-${var.instance_name}-ebs-attachment"
  role = aws_iam_role.docker_workload_role.id

  policy = data.aws_iam_policy_document.ebs_volume_attachment.json
}

data "aws_iam_policy_document" "ebs_volume_attachment" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:volume/*",
    ]
  }
}

# -----------------------------------------------
# Route53 DNS Registration Policy (for internal DNS)
# -----------------------------------------------

resource "aws_iam_role_policy" "route53_registration" {
  count = var.enable_internal_dns ? 1 : 0
  name  = "${var.solution_name}-${var.instance_name}-route53-registration"
  role  = aws_iam_role.docker_workload_role.id

  policy = data.aws_iam_policy_document.route53_registration[0].json

  depends_on = [aws_iam_role.docker_workload_role]
}

data "aws_iam_policy_document" "route53_registration" {
  count = var.enable_internal_dns ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [data.aws_route53_zone.internal[0].arn]
  }
}

# -----------------------------------------------
# Secrets Access Policy (SSM Parameter Store & Secrets Manager)
# -----------------------------------------------

resource "aws_iam_role_policy" "secrets_access" {
  count = length(var.map_secrets) > 0 ? 1 : 0
  name  = "${var.solution_name}-${var.instance_name}-secrets-access"
  role  = aws_iam_role.docker_workload_role.id

  policy = data.aws_iam_policy_document.secrets_access[0].json
}

data "aws_iam_policy_document" "secrets_access" {
  count = length(var.map_secrets) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(local.ssm_secret_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ssm:DescribeParameters",
        "ssm:GetParameter",
        "ssm:GetParameters",
      ]
      resources = local.ssm_secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.ssm_secret_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      resources = ["arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ssm.${data.aws_region.current.id}.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = length(local.sm_secret_arns) > 0 ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.sm_secret_arns
    }
  }
}

# -----------------------------------------------
# Additional Policy Attachments (user-provided)
# -----------------------------------------------

resource "aws_iam_role_policy_attachment" "additional_policies" {
  count      = length(var.additional_iam_policy_arns)
  role       = aws_iam_role.docker_workload_role.name
  policy_arn = var.additional_iam_policy_arns[count.index]
}
