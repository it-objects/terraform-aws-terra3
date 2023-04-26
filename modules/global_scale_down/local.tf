locals {
  scale_up_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor00",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for ecs_ec2_instances_autoscaling_group_arn in var.ecs_ec2_instances_autoscaling_group_arn : ecs_ec2_instances_autoscaling_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor01",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for nat_instances_autoscaling_group_arn in var.nat_instances_autoscaling_group_arn : nat_instances_autoscaling_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor02",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for bastion_host_autoscaling_group_arn in var.bastion_host_autoscaling_group_arn : bastion_host_autoscaling_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor03",
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
          "Sid" : "VisualEditor04",
          "Effect" : "Allow",
          "Action" : [
            "ecs:UpdateService"
          ],
          "Resource" : var.ecs_service_arn
        },

        {
          "Sid" : "VisualEditor05",
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
          "Sid" : "VisualEditor06",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : var.redis_cluster_arn
        },

        {
          "Sid" : "VisualEditor07",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : var.redis_subnet_group_arn
        },

        {
          "Sid" : "VisualEditor08",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : [
            var.redis_security_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor09",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : [
            "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parametergroup:*"
          ]
        }

      ]
  })

  scale_down_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor00",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for ecs_ec2_instances_autoscaling_group_arn in var.ecs_ec2_instances_autoscaling_group_arn : ecs_ec2_instances_autoscaling_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor01",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for nat_instances_autoscaling_group_arn in var.nat_instances_autoscaling_group_arn : nat_instances_autoscaling_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor02",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for bastion_host_autoscaling_group_arn in var.bastion_host_autoscaling_group_arn : bastion_host_autoscaling_group_arn
          ]
        },

        {
          "Sid" : "VisualEditor03",
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
          "Sid" : "VisualEditor04",
          "Effect" : "Allow",
          "Action" : [
            "ecs:UpdateService"
          ],
          "Resource" : var.ecs_service_arn
        },

        {
          "Sid" : "VisualEditor05",
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
          "Sid" : "VisualEditor06",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:DeleteCacheCluster"
          ],
          "Resource" : var.redis_cluster_arn
        }
      ]
  })
}
