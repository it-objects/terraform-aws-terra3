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
            for ecs_ec2_instances_autoscaling_group_arn in var.ecs_ec2_instances_autoscaling_group_arn : "${ecs_ec2_instances_autoscaling_group_arn}"
          ]
        },

        {
          "Sid" : "VisualEditor01",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for nat_instances_autoscaling_group_arn in var.nat_instances_autoscaling_group_arn : "${nat_instances_autoscaling_group_arn}"
          ]
        },

        {
          "Sid" : "VisualEditor02",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for bastion_host_autoscaling_group_arn in var.bastion_host_autoscaling_group_arn : "${bastion_host_autoscaling_group_arn}"
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
          "Resource" : [
            for ecs_service_names in var.ecs_service_names : "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${local.cluster_name[0]}/${ecs_service_names}"
          ]
        },

        {
          "Sid" : "VisualEditor05",
          "Effect" : "Allow",
          "Action" : [
            "rds:DescribeDBInstances",
            "rds:StartDBInstance"
          ],
          "Resource" : [
            "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${local.db_instance_name[0]}"
          ]
        },

        {
          "Sid" : "VisualEditor06",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : [
            "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:${local.redis_cluster_id[0]}"
          ]
        },

        {
          "Sid" : "VisualEditor07",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : [
            for redis_subnet_group_name in var.redis_subnet_group_name : "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnetgroup:${redis_subnet_group_name}"
          ]
        },

        {
          "Sid" : "VisualEditor08",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:CreateCacheCluster"
          ],
          "Resource" : [
            for redis_security_group_ids in var.redis_security_group_ids : "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:securitygroup:${redis_security_group_ids}"
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
            for ecs_ec2_instances_autoscaling_group_arn in var.ecs_ec2_instances_autoscaling_group_arn : "${ecs_ec2_instances_autoscaling_group_arn}"
          ]
        },

        {
          "Sid" : "VisualEditor01",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for nat_instances_autoscaling_group_arn in var.nat_instances_autoscaling_group_arn : "${nat_instances_autoscaling_group_arn}"
          ]
        },

        {
          "Sid" : "VisualEditor02",
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:UpdateAutoScalingGroup",
          ],
          "Resource" : [
            for bastion_host_autoscaling_group_arn in var.bastion_host_autoscaling_group_arn : "${bastion_host_autoscaling_group_arn}"
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
          "Resource" : [
            for ecs_service_names in var.ecs_service_names : "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${local.cluster_name[0]}/${ecs_service_names}"
          ]
        },

        {
          "Sid" : "VisualEditor05",
          "Effect" : "Allow",
          "Action" : [
            "rds:DescribeDBInstances",
            "rds:StopDBInstance"
          ],
          "Resource" : [
            "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${local.db_instance_name[0]}"
          ]
        },

        {
          "Sid" : "VisualEditor06",
          "Effect" : "Allow",
          "Action" : [
            "elasticache:DeleteCacheCluster"
          ],
          "Resource" : [
            "arn:aws:elasticache:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:${local.redis_cluster_id[0]}"
          ]

        }
      ]
  })
}
