# ---------------------------------------------------------------------------------------------------------------------
# Global Scale Up resources.
# ASG = MinSize, MaxSize, DesiredCapacity = 1.
# ECS = DesiredCount = 1
# DB  = StartDBInstanceCommand (It will start the DB)
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-lambda-enable-tracing
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
                "ecs:UpdateService",
                "iam:GetRole",
                "iam:PassRole",
                "rds:DescribeDBInstances",
                "autoscaling:UpdateAutoScalingGroup",
                "rds:StartDBInstance"
            ],
            "Resource": [
                "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:service/*/*",
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*",
                "arn:aws:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*",
                "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:*"
            ]
        }
    ]
}
  EOT
}

locals {
  cluster_name     = split(",", var.cluster_name)
  db_instance_name = split(",", var.db_instance_name)
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
      schedule_expression = var.environment_hibernation_wakeup_schedule
    }
  }

  targets = {
    scale_up = [
      {
        name = "${var.solution_name}-global-scale-up"
        arn  = module.lambda_scale_up[0].lambda_function_arn
        input = jsonencode({
          "cluster_name" : local.cluster_name,
          "ecs_service_name" : var.ecs_service_names,
          "ecs_desire_task_count" : var.ecs_desire_task_count,
          "db_instance_name" : local.db_instance_name,
          "bastion_host_asg_name" : var.bastion_host_asg_name,
          "bastion_host_asg_max_capacity" : var.bastion_host_asg_max_capacity,
          "bastion_host_asg_min_capacity" : var.bastion_host_asg_min_capacity,
          "bastion_host_asg_desired_capacity" : var.bastion_host_asg_desired_capacity,
          "nat_instances_asg_names" : var.nat_instances_asg_names,
          "nat_instances_asg_max_capacity" : var.nat_instances_asg_max_capacity,
          "nat_instances_asg_min_capacity" : var.nat_instances_asg_min_capacity,
        "nat_instances_asg_desired_capacity" : var.nat_instances_asg_desired_capacity })
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
#tfsec:ignore:aws-lambda-enable-tracing
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
                "ecs:UpdateService",
                "iam:GetRole",
                "iam:PassRole",
                "rds:DescribeDBInstances",
                "autoscaling:UpdateAutoScalingGroup",
                "rds:StopDBInstance"
            ],
            "Resource": [
                "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:service/*/*",
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*",
                "arn:aws:autoscaling:*:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/*",
                "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:*"
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
      schedule_expression = var.environment_hibernation_sleep_schedule
    }
  }

  targets = {
    scale_down = [
      {
        name = "${var.solution_name}-global-scale--down"
        arn  = module.lambda_scale_down[0].lambda_function_arn
        input = jsonencode({
          "cluster_name" : local.cluster_name,
          "ecs_service_name" : var.ecs_service_names,
          "ecs_desire_task_count" : [0],
          "db_instance_name" : local.db_instance_name,
          "bastion_host_asg_name" : var.bastion_host_asg_name,
          "bastion_host_asg_max_capacity" : [0],
          "bastion_host_asg_min_capacity" : [0],
          "bastion_host_asg_desired_capacity" : [0],
          "nat_instances_asg_names" : var.nat_instances_asg_names,
          "nat_instances_asg_max_capacity" : [0],
          "nat_instances_asg_min_capacity" : [0],
        "nat_instances_asg_desired_capacity" : [0] })
      }
    ]
  }
}
