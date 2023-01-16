# ---------------------------------------------------------------------------------------------------------------------
# This is an example of showcasing Terra3's cronjob feature. This allows to schedule a recurring
# HTTPS API call which can be used for maintenance activities that need to be triggered regularly.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "terra3-cron"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  enable_s3_for_static_website = true

  # Lambda in an AWS-managed VPC does not require NAT for internet access
  nat = "NO_NAT"

  # to see results for this example visit https://webhook.site/#!/326a091a-bd02-43e8-b414-6ab02ef49b85
  # to test your own use case visit https://webhook.site/
  # to define your own crontab visit https://crontab.guru/ or https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html#eb-cron-expressions
  # for rate expressions visit https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html#eb-rate-expressions
  enable_scheduled_https_api_call  = true
  scheduled_https_api_call_crontab = "rate(1 minute)"
  scheduled_https_api_call_url     = "https://webhook.site/326a091a-bd02-43e8-b414-6ab02ef49b85"
}
