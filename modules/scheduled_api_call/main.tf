# ---------------------------------------------------------------------------------------------------------------------
# scheduled HTTPS API call
# ---------------------------------------------------------------------------------------------------------------------
module "eventbridge" {
  count = var.enable_scheduled_https_api_call ? 1 : 0

  source  = "terraform-aws-modules/eventbridge/aws"
  version = "3.2.3"

  create_bus = false

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = var.scheduled_https_api_call_crontab
    }
  }

  targets = {
    crons = [
      {
        name  = "${var.solution_name}-lambda-https-cron"
        arn   = module.lambda[0].lambda_function_arn
        input = jsonencode({ "url" : var.scheduled_https_api_call_url, "httpVerb" : "GET" })
      }
    ]
  }
}

# tfsec:ignore:aws-lambda-enable-tracing
module "lambda" {
  count = var.enable_scheduled_https_api_call ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.3"

  function_name = "${var.solution_name}-scheduled-https-api-call"
  description   = "scheduled https api call"
  handler       = "api_call.handler"
  runtime       = "nodejs20.x"
  source_path   = "${path.module}/api_call.js"

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge[0].eventbridge_rule_arns["crons"]
    }
  }
}
