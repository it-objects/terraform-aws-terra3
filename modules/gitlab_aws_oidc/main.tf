# ---------------------------------------------------------------------------------------------------------------------
# See:
# https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_gitlab_arn]
    }
    condition {
      test     = "StringLike" #
      variable = "${var.oidc_gitlab_url}:${var.match_field}"
      values   = var.match_value
    }
  }
}

resource "aws_iam_role" "gitlab_ci" {
  name                = "deployment_role_${var.app_name}_oidc"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.deployment_policy.arn]
}

resource "aws_iam_policy" "deployment_policy" {
  name        = "deployment_${var.app_name}_policy"
  path        = "/"
  description = "Policy used to deploy to AWS from GitLab."

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : var.policy_statements
    }
  )
}
