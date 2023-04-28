locals {
  scale_up_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleUpAutoscaling",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : concat(var.ecs_ec2_instances_autoscaling_group_arn, var.nat_instances_autoscaling_group_arn, var.bastion_host_autoscaling_group_arn)
        },

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
          "Sid" : "ScaleUpUpdateECS",
          "Effect" : "Allow",
          "Action" : [
            "ecs:UpdateService"
          ],
          "Resource" : var.ecs_service_arn
        },

        {
          "Sid" : "ScaleUpDB",
          "Effect" : "Allow",
          "Action" : [
            "rds:DescribeDBInstances",
            "rds:StartDBInstance"
          ],
          "Resource" : [
            var.db_instance_arn
          ]
        },

        {
          "Sid" : "ScaleUpRedis",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : concat(var.redis_cluster_arn, var.redis_subnet_group_arn, [var.redis_security_group_arn], ["arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parametergroup:*"])
        },
      ]
  })

  scale_down_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ScaleDownAutoscaling",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : concat(var.ecs_ec2_instances_autoscaling_group_arn, var.nat_instances_autoscaling_group_arn, var.bastion_host_autoscaling_group_arn)
        },

        {
          "Sid" : "ScaleDownIAM",
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
          "Sid" : "ScaleDownUpdateECS",
          "Effect" : "Allow",
          "Action" : [
            "ecs:UpdateService"
          ],
          "Resource" : var.ecs_service_arn
        },

        {
          "Sid" : "ScaleDownDB",
          "Effect" : "Allow",
          "Action" : [
            "rds:DescribeDBInstances",
            "rds:StopDBInstance"
          ],
          "Resource" : [
            var.db_instance_arn
          ]
        },

        {
          "Sid" : "sScaleDownRedis",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:DeleteCacheCluster"
          ],
          "Resource" : var.redis_cluster_arn
        }
      ]
  })
}
