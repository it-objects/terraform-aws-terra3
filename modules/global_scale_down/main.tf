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
  timeout       = 100

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
    ecs_service_data    = local.ecs_service_data
    scale_up_parameters = local.scale_up_parameters
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
        arn  = module.lambda_scale_down[0].lambda_function_arn
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
  timeout       = 100

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
    ecs_service_data    = local.ecs_service_data
    scale_up_parameters = local.scale_up_parameters
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
