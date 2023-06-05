locals {
  asg_arn   = concat(var.ecs_ec2_instances_autoscaling_group_arn, var.nat_instances_autoscaling_group_arn, var.bastion_host_autoscaling_group_arn)
  redis_arn = concat(var.redis_cluster_arn, var.redis_subnet_group_arn, [var.redis_security_group_arn], ["arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parametergroup:*"])
}

resource "aws_iam_policy" "scale_up_down_asg_policy" {
  count       = length(local.asg_arn) != 0 && var.enable_environment_hibernation_sleep_schedule == true ? 1 : 0
  name        = "${var.solution_name}-scale_up_down_asg_policy"
  path        = "/"
  description = "Scale up/down auto scaling policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleUpDownAutoscaling",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : local.asg_arn
      }]
  })
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "scale_up_down_ecs_policy" {
  count       = length(var.ecs_service_arn) != 0 && var.enable_environment_hibernation_sleep_schedule == true ? 1 : 0
  name        = "${var.solution_name}-scale_up_down_ecs_policy"
  path        = "/"
  description = "Scale up/down ECS policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleUpDownUpdateECS",
          "Effect" : "Allow",
          "Action" : [
            "ecs:UpdateService"
          ],
          "Resource" : "*"
          Condition = {
            ArnEquals = {
              "ecs:cluster" : var.cluster_arn
            }
          }
        },
        {
          "Sid" : "ScaleUpDownListECS",
          "Effect" : "Allow",
          "Action" : [
            "ecs:ListServices",
            "ecs:DescribeServices"
          ],
          "Resource" : "*"
      }]
  })
}

resource "aws_iam_policy" "scale_up_down_iam_policy" {
  count       = var.enable_environment_hibernation_sleep_schedule ? 1 : 0
  name        = "${var.solution_name}-scale_up_down_iam_policy"
  path        = "/"
  description = "Scale up/down iam policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleUpIAM",
          "Effect" : "Allow",
          "Action" : [
            "iam:GetRole",
            "iam:PassRole"
          ],
          "Resource" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
          ]
        },
        {
          "Sid" : "ScaleUpSSM",
          "Effect" : "Allow",
          "Action" : [
            "ssm:PutParameter",
            "ssm:GetParameter"
          ],
          "Resource" : [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/ecs_service_data"
          ]
        }
      ]
  })
}

resource "aws_iam_policy" "scale_up_rds_db_policy" {
  count       = length(var.db_instance_arn) != 0 && var.enable_environment_hibernation_sleep_schedule == true ? 1 : 0
  name        = "${var.solution_name}-scale_up_rds_db_policy"
  path        = "/"
  description = "Scale up rds policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleUpDB",
          "Effect" : "Allow",
          "Action" : [
            "rds:DescribeDBInstances",
            "rds:StartDBInstance"
          ],
          "Resource" : var.db_instance_arn
      }]
  })
}

resource "aws_iam_policy" "scale_down_rds_db_policy" {
  count       = length(var.db_instance_arn) != 0 && var.enable_environment_hibernation_sleep_schedule == true ? 1 : 0
  name        = "${var.solution_name}-scale_down_rds_db_policy"
  path        = "/"
  description = "Scale down rds policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleDownDB",
          "Effect" : "Allow",
          "Action" : [
            "rds:DescribeDBInstances",
            "rds:StopDBInstance"
          ],
          "Resource" : var.db_instance_arn
      }]
  })
}

resource "aws_iam_policy" "scale_up_redis_policy" {
  count       = length(var.redis_cluster_arn) != 0 && var.enable_environment_hibernation_sleep_schedule == true ? 1 : 0
  name        = "${var.solution_name}-scale_up_redis_policy"
  path        = "/"
  description = "Scale up redis policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleUpRedis",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : local.redis_arn
      }]
  })
}

resource "aws_iam_policy" "scale_down_redis_policy" {
  count       = length(var.redis_cluster_arn) != 0 && var.enable_environment_hibernation_sleep_schedule == true ? 1 : 0
  name        = "${var.solution_name}-scale_down_redis_policy"
  path        = "/"
  description = "Scale down redis policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleDownRedis",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:DeleteCacheCluster"
          ],
          "Resource" : var.redis_cluster_arn
      }]
  })
}
