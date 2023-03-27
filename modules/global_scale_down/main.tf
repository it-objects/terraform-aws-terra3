# ---------------------------------------------------------------------------------------------------------------------
# Global Scale Up resources.
# ASG = MinSize, MaxSize, DesiredCapacity = 1.
# ECS = DesiredCount = 1
# DB  = StartDBInstanceCommand (It will start the DB)
# ---------------------------------------------------------------------------------------------------------------------

module "lambda_scale_up" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "4.9.0"

  function_name = "${var.solution_name}-global-scale-up"
  description   = "Performs global scale up"
  handler       = "scale_up.handler"
  runtime       = "nodejs18.x"
  source_path   = "${path.module}/scale_up.mjs"

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge_scale_up[0].eventbridge_rule_arns["scale_up"]
    }
  }

  attach_policy_json = true
  policy_json        = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                  "autoscaling:UpdateAutoScalingGroup",
                  "rds:DescribeDBInstances",
                  "rds:StopDBInstance",
                  "rds:StartDBInstance",
                  "iam:GetRole",
                  "ecs:UpdateService",
                  "iam:PassRole"
                ],
                "Resource": [
                    "arn:aws:autoscaling:*:531874807515:autoScalingGroup:*:autoScalingGroupName/*",
                    "arn:aws:rds:*:531874807515:db:*",
                    "arn:aws:iam::531874807515:role/*",
                    "arn:aws:ecs:*:531874807515:service/*/*"
                ]
            }
        ]
    }
  EOT
}

module "eventbridge_scale_up" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source    = "terraform-aws-modules/eventbridge/aws"
  version   = "1.17.2"
  role_name = "${var.solution_name}-eventbridge-global-scale-up"

  create_bus = false

  rules = {
    scale_up = {
      name                = "${var.solution_name}-global-scale-up"
      description         = "Trigger for a Lambda to enable global scale up."
      schedule_expression = "rate(1 minute)" #var.environment_hibernation_wakeup_schedule
    }
  }

  targets = {
    scale_up = [
      {
        name  = "${var.solution_name}-global-scale-up"
        arn   = module.lambda_scale_up[0].lambda_function_arn
        input = jsonencode({ "min" : 0, "max" : 2, "desired" : 1 })
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Global Scale Down resources.
# ASG = MinSize, MaxSize, DesiredCapacity = 0.
# ECS = DesiredCount = 0
# DB  = StopDBInstanceCommand (It will stop the DB temporarily)
# ---------------------------------------------------------------------------------------------------------------------

module "lambda_scale_down" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "4.9.0"

  function_name = "${var.solution_name}-global-scale-down"
  description   = "Performs global scale down"
  handler       = "scale_down.handler"
  runtime       = "nodejs18.x"
  source_path   = "${path.module}/scale_down.mjs"

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge_scale_down[0].eventbridge_rule_arns["scale_down"]
    }
  }

  attach_policy_json = true
  policy_json        = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                  "autoscaling:UpdateAutoScalingGroup",
                  "rds:DescribeDBInstances",
                  "rds:StopDBInstance",
                  "rds:StartDBInstance",
                  "iam:GetRole",
                  "ecs:UpdateService",
                  "iam:PassRole"
                ],
                "Resource": [
                    "arn:aws:autoscaling:*:531874807515:autoScalingGroup:*:autoScalingGroupName/*",
                    "arn:aws:rds:*:531874807515:db:*",
                    "arn:aws:iam::531874807515:role/*",
                    "arn:aws:ecs:*:531874807515:service/*/*"
                ]
            }
        ]
    }
  EOT
}

module "eventbridge_scale_down" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source    = "terraform-aws-modules/eventbridge/aws"
  version   = "1.17.2"
  role_name = "${var.solution_name}-eventbridge-global-scale--down"

  create_bus = false

  rules = {
    scale_down = {
      name                = "${var.solution_name}-global-scale--down"
      description         = "Trigger for a Lambda to enable global scale down."
      schedule_expression = "rate(1 minute)" #var.environment_hibernation_sleep_schedule
    }
  }

  targets = {
    scale_down = [
      {
        name = "${var.solution_name}-global-scale--down"
        arn  = module.lambda_scale_down[0].lambda_function_arn
        input = jsonencode({ "min" : 0, "max" : 2, "desired" : 1,
          "clustername" : var.cluster_name,
          "ecs_service_names" : var.ecs_service_names,
          "ecs_desire_task_count" : var.ecs_desire_task_count
        "dbname" : var.db_identifier })
      }
    ]
  }
}
