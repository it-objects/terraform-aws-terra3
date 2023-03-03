module "lambda" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "4.9.0"

  function_name = "${var.solution_name}-ecs-container-sleep"
  description   = "ecs container in sleep mode"
  handler       = "ecs_container_sleep.lambda_handler"
  runtime       = "python3.9"
  source_path   = "${path.module}/ecs_container_sleep.py"

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge[0].eventbridge_rule_arns["crons"]
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
                "Action": "ecs:UpdateService",
                "Resource": "arn:aws:ecs:*:531874807515:service/*/*"
            }
        ]
    }
  EOT
}

module "eventbridge" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.17.2"

  create_bus = false

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = "rate(1 minute)"
    }
  }

  targets = {
    crons = [
      {
        name  = "${var.solution_name}-ecs-container-sleep"
        arn   = module.lambda[0].lambda_function_arn
        input = jsonencode({ "job" : "cron-by-rate" })
      }
    ]
  }
}
