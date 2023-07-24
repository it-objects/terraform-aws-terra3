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

  ecs_service_data         = "/${var.solution_name}/global_scale_down/ecs_service_data"
  scale_up_parameters      = "/${var.solution_name}/global_scale_down/scale_up_parameters"
  hibernation_state        = " /${var.solution_name}/global_scale_down/hibernation_state"
  admin_secret_credentials = aws_secretsmanager_secret.hashed_credentials.arn
}

module "lambda_scale_up" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "4.18.0"

  function_name = "${var.solution_name}-global-scale-up"
  description   = "Performs global scale up"
  handler       = "scale_up.handler"
  runtime       = "nodejs18.x"
  source_path   = "${path.module}/scale_up.mjs"
  timeout       = 600

  create_current_version_allowed_triggers = false
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
    admin_secret_credentials = local.admin_secret_credentials
  }
}

module "eventbridge_scale_up" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source    = "terraform-aws-modules/eventbridge/aws"
  version   = "1.17.2"
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
  version = "4.18.0"

  function_name = "${var.solution_name}-global-scale-down"
  description   = "Performs global scale down"
  handler       = "scale_down.handler"
  runtime       = "nodejs18.x"
  source_path   = "${path.module}/scale_down.mjs"
  timeout       = 600

  create_current_version_allowed_triggers = false
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
    admin_secret_credentials = local.admin_secret_credentials
  }
}

module "eventbridge_scale_down" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source    = "terraform-aws-modules/eventbridge/aws"
  version   = "1.17.2"
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
        })
      }
    ]
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.solution_name}-global-scale-up-and-down-hosting-bucket-${random_string.random_s3_postfix.result}"
}

resource "random_string" "random_s3_postfix" {
  length    = 4
  special   = false
  min_lower = 4
}

resource "aws_s3_bucket_website_configuration" "b_website" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "index.html"
  source = "${path.module}/index.html"
}

resource "aws_s3_bucket_ownership_controls" "s3_data_bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_lambda_function_url" "scale_down_lambda_function_url" {
  function_name      = module.lambda_scale_down[0].lambda_function_name
  authorization_type = "NONE" #"AWS_IAM"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "scale_up_lambda_function_url" {
  function_name      = module.lambda_scale_up[0].lambda_function_name
  authorization_type = "NONE" #"AWS_IAM"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    max_age           = 86400
  }
}

data "template_file" "index" {
  template = file("${path.module}/index.tpl")

  vars = {
    scale_down_api_endpoint = aws_lambda_function_url.scale_down_lambda_function_url.function_url
    scale_up_api_endpoint   = aws_lambda_function_url.scale_up_lambda_function_url.function_url
  }
}

resource "local_file" "local_index" {
  content  = data.template_file.index.rendered
  filename = "${path.module}/index.html"
}

resource "aws_secretsmanager_secret" "hashed_credentials" {
  name = "hashed-credentials-${random_string.random_secret_character.result}"
}

resource "aws_secretsmanager_secret_version" "hashed_credentials_version" {
  secret_id = aws_secretsmanager_secret.hashed_credentials.id
  secret_string = jsonencode({
    "hash" : random_string.random_secret_hash.result
  })
}

resource "random_string" "random_secret_character" {
  length    = 5
  special   = false
  min_lower = 4
}

resource "random_string" "random_secret_hash" {
  length  = 16
  special = false
  lower   = true
}
