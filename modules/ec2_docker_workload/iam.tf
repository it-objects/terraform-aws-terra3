# -----------------------------------------------
# EC2 Docker Workload Module - IAM
# -----------------------------------------------

# -----------------------------------------------
# IAM Role for EC2 Instance
# -----------------------------------------------

resource "aws_iam_role" "docker_workload_role" {
  name_prefix = "${var.solution_name}-${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.solution_name}-${var.instance_name}-role"
    }
  )
}

# -----------------------------------------------
# Instance Profile
# -----------------------------------------------

resource "aws_iam_instance_profile" "docker_workload_profile" {
  name_prefix = "${var.solution_name}-${var.instance_name}-"
  role        = aws_iam_role.docker_workload_role.name
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
  name_prefix = "cloudwatch-logs-"
  role        = aws_iam_role.docker_workload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.docker_logs.arn,
          "${aws_cloudwatch_log_group.docker_logs.arn}:*"
        ]
      }
    ]
  })

  depends_on = [aws_cloudwatch_log_group.docker_logs]
}

# -----------------------------------------------
# ECR Access Policy (conditional)
# -----------------------------------------------

resource "aws_iam_role_policy" "ecr_access" {
  count       = var.enable_ecr_access ? 1 : 0
  name_prefix = "ecr-access-"
  role        = aws_iam_role.docker_workload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------
# EBS Volume Attachment Policy (for persistent volumes)
# -----------------------------------------------

resource "aws_iam_role_policy" "ebs_volume_attachment" {
  name_prefix = "ebs-attachment-"
  role        = aws_iam_role.docker_workload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------
# Route53 DNS Registration Policy (for internal DNS)
# -----------------------------------------------

resource "aws_iam_role_policy" "route53_registration" {
  count       = var.enable_internal_dns ? 1 : 0
  name_prefix = "route53-registration-"
  role        = aws_iam_role.docker_workload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = try(data.aws_route53_zone.internal[0].arn, "arn:aws:route53:::hostedzone/*")
      }
    ]
  })

  depends_on = [aws_iam_role.docker_workload_role]
}

# -----------------------------------------------
# Additional Policy Attachments (user-provided)
# -----------------------------------------------

resource "aws_iam_role_policy_attachment" "additional_policies" {
  count      = length(var.additional_iam_policy_arns)
  role       = aws_iam_role.docker_workload_role.name
  policy_arn = var.additional_iam_policy_arns[count.index]
}
