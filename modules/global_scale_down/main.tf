# ---------------------------------------------------------------------------------------------------------------------
# Global Scale Up resources.
# ASG = MinSize, MaxSize, DesiredCapacity = 1.
# ECS = DesiredCount = 1
# DB  = StartDBInstanceCommand (It will start the DB)
# redis = CreateCacheCluster (It will create the redis cluster)
# ---------------------------------------------------------------------------------------------------------------------
locals {
  scale_up_policies_arns = concat(
    aws_iam_policy.scale_up_down_asg_policy[*].arn,
    aws_iam_policy.scale_up_down_ecs_policy[*].arn,
    aws_iam_policy.scale_up_down_iam_policy[*].arn,
    aws_iam_policy.scale_up_rds_db_policy[*].arn,
    aws_iam_policy.scale_up_redis_policy[*].arn
  )

  scale_down_policies_arns = concat(
    aws_iam_policy.scale_up_down_asg_policy[*].arn,
    aws_iam_policy.scale_up_down_ecs_policy[*].arn,
    aws_iam_policy.scale_up_down_iam_policy[*].arn,
    aws_iam_policy.scale_down_rds_db_policy[*].arn,
    aws_iam_policy.scale_down_redis_policy[*].arn
  )

  ecs_service_data    = "/${var.solution_name}/global_scale_down/ecs_service_data"
  scale_up_parameters = "/${var.solution_name}/global_scale_down/scale_up_parameters"
  hibernation_state   = "/${var.solution_name}/global_scale_down/hibernation_state"
  token               = "/${var.solution_name}/global_scale_down/token"

  scale_down_api_endpoint = var.enable_environment_hibernation_sleep_schedule ? aws_lambda_function_url.scale_down_lambda_function_url[0].function_url : ""
  scale_up_api_endpoint   = var.enable_environment_hibernation_sleep_schedule ? aws_lambda_function_url.scale_up_lambda_function_url[0].function_url : ""
  status_api_endpoint     = var.enable_environment_hibernation_sleep_schedule ? aws_lambda_function_url.status_lambda_function_url[0].function_url : ""

  json_data = jsonencode({
    user_token = var.enable_environment_hibernation_sleep_schedule ? random_string.s3-admin-website-auth-token[0].result : ""
    api_token  = var.enable_environment_hibernation_sleep_schedule ? random_string.api-auth-token[0].result : ""
  })
}

module "lambda_scale_up" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.3"

  function_name = "${var.solution_name}-global-scale-up"
  description   = "Performs global scale up"
  handler       = "scale_up.handler"
  runtime       = "nodejs20.x"
  source_path   = "${path.module}/scale_up.mjs"
  timeout       = 900

  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 30
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge_scale_up[0].eventbridge_rule_arns["${var.solution_name}-scale_up"]
    }
  }

  tracing_mode          = "Active"
  attach_tracing_policy = true

  attach_policies    = true
  policies           = local.scale_up_policies_arns
  number_of_policies = length(local.scale_up_policies_arns)

  environment_variables = {
    ecs_service_data         = local.ecs_service_data
    scale_up_parameters      = local.scale_up_parameters
    hibernation_state        = local.hibernation_state
    admin_secret_credentials = local.token
  }
}

resource "aws_lambda_function_url" "scale_up_lambda_function_url" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  function_name      = module.lambda_scale_up[0].lambda_function_name
  authorization_type = "NONE" #"AWS_IAM"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    max_age           = 86400
  }
}

module "eventbridge_scale_up" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source    = "terraform-aws-modules/eventbridge/aws"
  version   = "3.2.3"
  role_name = "${var.solution_name}-eventbridge-global-scale-up"

  create_bus = false

  rules = {
    "${var.solution_name}-scale_up" = {
      name                = "${var.solution_name}-global-scale-up"
      description         = "Trigger for a Lambda to enable global scale up."
      schedule_expression = var.environment_hibernation_wakeup_schedule
    }
  }

  targets = {
    "${var.solution_name}-scale_up" = [
      {
        name = "${var.solution_name}-global-scale-up"
        arn  = module.lambda_scale_up[0].lambda_function_arn
        input = jsonencode({
          "ecs_service_data" : local.ecs_service_data,
          "scale_up_parameters" : local.scale_up_parameters
          "api_token" : random_string.api-auth-token[0].result
        })
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Global Scale Down resources.
# ASG = MinSize, MaxSize, DesiredCapacity = 0.
# ECS = DesiredCount = 0
# DB  = StopDBInstanceCommand (It will stop the DB temporarily)
# redis = DeleteCacheCluster (It will delete the redis cluster)
# ---------------------------------------------------------------------------------------------------------------------
module "lambda_scale_down" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.3"

  function_name = "${var.solution_name}-global-scale-down"
  description   = "Performs global scale down"
  handler       = "scale_down.handler"
  runtime       = "nodejs20.x"
  source_path   = "${path.module}/scale_down.mjs"
  timeout       = 900

  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 30
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge_scale_down[0].eventbridge_rule_arns["${var.solution_name}-scale_down"]
    }
  }

  tracing_mode          = "Active"
  attach_tracing_policy = true

  attach_policies    = true
  policies           = local.scale_down_policies_arns
  number_of_policies = length(local.scale_down_policies_arns)

  environment_variables = {
    ecs_service_data         = local.ecs_service_data
    scale_up_parameters      = local.scale_up_parameters
    hibernation_state        = local.hibernation_state
    admin_secret_credentials = local.token
  }
}

resource "aws_lambda_function_url" "scale_down_lambda_function_url" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  function_name      = module.lambda_scale_down[0].lambda_function_name
  authorization_type = "NONE" #"AWS_IAM"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    max_age           = 86400
  }
}

module "eventbridge_scale_down" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source    = "terraform-aws-modules/eventbridge/aws"
  version   = "3.2.3"
  role_name = "${var.solution_name}-eventbridge-global-scale-down"

  create_bus = false

  rules = {
    "${var.solution_name}-scale_down" = {
      name                = "${var.solution_name}-global-scale-down"
      description         = "Trigger for a Lambda to enable global scale down."
      schedule_expression = var.environment_hibernation_sleep_schedule
    }
  }

  targets = {
    "${var.solution_name}-scale_down" = [
      {
        name = "${var.solution_name}-global-scale-down"
        arn  = module.lambda_scale_down[0].lambda_function_arn
        input = jsonencode({
          "api_token" : random_string.api-auth-token[0].result
        })
      }
    ]
  }
}

module "global_scale_status" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.3"

  function_name = "${var.solution_name}-global-scale-status"
  description   = "Shows the current status of deployment."
  handler       = "status.handler"
  runtime       = "nodejs20.x"
  source_path   = "${path.module}/status.mjs"
  timeout       = 900

  create_current_version_allowed_triggers = false
  cloudwatch_logs_retention_in_days       = 30

  tracing_mode          = "Active"
  attach_tracing_policy = true

  attach_policy = true
  policy        = aws_iam_policy.status_lambda_get_parameter[0].arn

  environment_variables = {
    hibernation_state = local.hibernation_state
  }
}

resource "aws_lambda_function_url" "status_lambda_function_url" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  function_name      = module.global_scale_status[0].lambda_function_name
  authorization_type = "NONE" #"AWS_IAM"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    max_age           = 86400
  }
}

#tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "bucket" {
  count         = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  bucket        = "${var.solution_name}-mini-admin-website-s3-bucket-${random_string.random_s3_postfix[0].result}"
  force_destroy = true
}

resource "random_string" "random_s3_postfix" {
  count     = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  length    = 4
  special   = false
  min_lower = 4
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_static_website_enc_config" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  bucket = aws_s3_bucket.bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "object" {
  count        = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  bucket       = aws_s3_bucket.bucket[0].id
  key          = "admin-terra3/index.html"
  source       = local_file.local_index[0].filename
  content_type = "text/html"
}

resource "aws_s3_bucket_ownership_controls" "s3_data_bucket" {
  count  = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  count  = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static_website_bucket_policy" {
  count  = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.bucket[0].arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_arn
          }
        }
      },
    ],
  })
}

locals {
  vars = templatefile("${path.module}/index.tpl", {
    scale_down_api_endpoint = local.scale_down_api_endpoint
    scale_up_api_endpoint   = local.scale_up_api_endpoint
    status_api_endpoint     = local.status_api_endpoint
    solution_name           = var.solution_name
  })
}

resource "local_file" "local_index" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  content  = local.vars
  filename = "${path.module}/index.html"
}

resource "random_string" "s3-admin-website-secret-postfix" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  length    = 5
  special   = false
  min_lower = 4
}

resource "random_string" "s3-admin-website-auth-token" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  length  = 16
  special = false
  lower   = true
}

resource "random_string" "api-auth-token" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  length  = 16
  special = false
  lower   = true
}

resource "aws_ssm_parameter" "mini-website-token" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  name  = "/${var.solution_name}/global_scale_down/token"
  type  = "SecureString" # This encrypts the value at rest
  value = local.json_data
}
