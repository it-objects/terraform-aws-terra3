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

# ---------------------------------------------------------------------------------------------------------------------
# Create KMS managed key e.g. for using SOPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "managed_env_key" {
  description             = "KMS key to encrypt and decrypt."
  deletion_window_in_days = 10

  # With below policies it's possible to lock one self and everybody else out from modifying or deleting this key.
  # This flag makes this situation more unrealistic.
  bypass_policy_lockout_safety_check = false

  policy = data.aws_iam_policy_document.key_permissions.json
}

resource "aws_kms_alias" "managed_key" {
  name          = "alias/${var.name}_key"
  target_key_id = aws_kms_key.managed_env_key.key_id
}

data "aws_iam_policy_document" "key_permissions" {

  # see https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-root-enable-iam
  statement {
    sid = "Enable IAM User Permissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*",
    ]
  }
}
