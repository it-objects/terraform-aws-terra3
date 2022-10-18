resource "aws_iam_user" "deployment_user" {
  name = "deployment_user"
  path = "/"
}

resource "aws_iam_user_policy" "deployment_user_user_policy" {
  name = "deployment_policy"
  user = aws_iam_user.deployment_user.name

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "deploymentpolicy",
          "Effect" : "Allow",
          "Action" : [
            "states:*",
            "application-autoscaling:*",
            "autoscaling:*",
            "rds:*",
            "s3:*",
            "logs:*",
            "elasticloadbalancing:*",
            "iam:*",
            "cloudfront:*",
            "secretsmanager:*",
            "cloudwatch:*",
            "ssm:*",
            "route53:*",
            "ecs:*",
            "ecr:*",
            "ec2:*",
            "ebs:*",
            "events:*",
            "acm:*",
            "kms:*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}
