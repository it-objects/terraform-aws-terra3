module "scheduled_api_call" {
  source = "registry.terraform.io/terraform-aws-modules/eventbridge/aws"

  # Schedules can only be created on default bus
  create_bus                    = false # use default bus
  create_connections            = true
  create_api_destinations       = true
  attach_api_destination_policy = true
  create_role                   = true # automatically create necessary IAM roles

  # Follow provided cron tab
  rules = {
    scheduled_api_call = {
      description         = "Cron scheduled API call."
      enabled             = true
      schedule_expression = var.scheduled_api_call_cron
    }
  }

  # Send to a fargate ECS cluster
  targets = {
    scheduled_api_call = [
      {
        name            = "${var.solution_name}-scheduled-api-call"
        destination     = "${var.solution_name}-api-endpoint"
        attach_role_arn = true

        retry_policy = {
          # optional: The maximum number of hours to keep unprocessed events for. The default value is 24 hours.
          maximum_event_age_in_seconds = 3600 # 1 hour
          # optional: The maximum number of times to retry sending an event to a target after an error occurs. The default value is 185 times.
          maximum_retry_attempts = 10
        }
      }
    ]
  }

  connections = {
    "${var.solution_name}-api-endpoint" = {
      authorization_type = "API_KEY"
      auth_parameters = {
        api_key = {
          key   = var.scheduled_api_apikey_key
          value = var.scheduled_api_apikey_value
        }
      }
    }
  }

  api_destinations = {
    "${var.solution_name}-api-endpoint" = {
      description                      = "Scheduled API call for ${var.solution_name}."
      invocation_endpoint              = var.scheduled_api_call_url
      http_method                      = var.scheduled_api_call_http_method
      invocation_rate_limit_per_second = 2
    }
  }
}
