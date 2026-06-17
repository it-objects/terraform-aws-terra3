data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  function_name = "${var.solution_name}-ami-update-${var.name_suffix}"
  common_tags = merge(
    var.tags,
    {
      Name      = local.function_name
      ManagedBy = "Terraform"
      Solution  = var.solution_name
    }
  )
}

# -----------------------------------------------------------------------------
# IAM Policy for Lambda
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "lambda_ami_updater" {
  name        = "${local.function_name}-policy"
  description = "Permissions for AMI update Lambda to describe images, update launch templates, and refresh ASGs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "DescribeEC2"
          Effect = "Allow"
          Action = [
            "ec2:DescribeImages",
            "ec2:DescribeLaunchTemplateVersions"
          ]
          Resource = "*"
        },
        {
          Sid    = "UpdateLaunchTemplate"
          Effect = "Allow"
          Action = [
            "ec2:CreateLaunchTemplateVersion"
          ]
          Resource = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:launch-template/${var.launch_template_id}"
        },
        {
          Sid      = "DescribeASGRefreshes"
          Effect   = "Allow"
          Action   = ["autoscaling:DescribeInstanceRefreshes"]
          Resource = "*"
        },
        {
          Sid    = "StartASGRefresh"
          Effect = "Allow"
          Action = [
            "autoscaling:StartInstanceRefresh"
          ]
          Resource = "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.asg_name}"
        }
      ],
      var.sns_topic_arn != "" ? [
        {
          Sid      = "PublishSNS"
          Effect   = "Allow"
          Action   = ["sns:Publish"]
          Resource = var.sns_topic_arn
        }
      ] : []
    )
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

#tfsec:ignore:aws-lambda-enable-tracing
module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name = local.function_name
  description   = "Checks for new AMIs and triggers instance refresh for ${var.name_suffix}"
  handler       = "ami_updater.handler"
  runtime       = "nodejs24.x"
  timeout       = 120
  source_path   = "${path.module}/ami_updater.mjs"

  trigger_on_package_timestamp = false

  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 30

  attach_policies    = true
  policies           = [aws_iam_policy.lambda_ami_updater.arn]
  number_of_policies = 1

  environment_variables = {
    LAUNCH_TEMPLATE_ID     = var.launch_template_id
    ASG_NAME               = var.asg_name
    AMI_OWNERS             = jsonencode(var.ami_owners)
    AMI_NAME_FILTER        = var.ami_name_filter
    AMI_ARCHITECTURE       = var.ami_architecture
    AMI_ADDITIONAL_FILTERS = jsonencode(var.ami_additional_filters)
    MIN_HEALTHY_PERCENTAGE = tostring(var.min_healthy_percentage)
    INSTANCE_WARMUP        = tostring(var.instance_warmup_seconds)
    SNS_TOPIC_ARN          = var.sns_topic_arn
  }

  allowed_triggers = {
    AmiCheckSchedule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge.eventbridge_rule_arns[local.function_name]
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EventBridge Schedule
# -----------------------------------------------------------------------------

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  create_bus                 = false
  create_role                = false
  create_log_delivery_source = false

  rules = {
    "${local.function_name}" = {
      description         = "Periodic AMI update check for ${var.name_suffix}"
      schedule_expression = var.schedule_expression
    }
  }

  targets = {
    "${local.function_name}" = [
      {
        name = "${local.function_name}-target"
        arn  = module.lambda.lambda_function_arn
      }
    ]
  }

  tags = local.common_tags
}
