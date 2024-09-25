# ---------------------------------------------------------------------------------------------------------------------
# deployment_role_infra_oidc
# ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "infra_deployment_role_postfix" {
  for_each = var.addOidcUrlToIamInfraRoleMapping

  length    = 4
  special   = false
  min_lower = 4
}

resource "aws_iam_role" "infra_gitlab_ci" {
  for_each = var.addOidcUrlToIamInfraRoleMapping

  name                = "deployment_role_infra_oidc_${random_string.infra_deployment_role_postfix[each.key].result}"
  assume_role_policy  = data.aws_iam_policy_document.infra_assume_role_policy[each.key].json
  managed_policy_arns = [aws_iam_policy.infra_deployment_policy[each.key].arn]
}

data "aws_iam_openid_connect_provider" "infra_openid_connect_provider" {
  for_each = var.addOidcUrlToIamInfraRoleMapping
  url      = "https://${each.key}"
}

data "aws_iam_policy_document" "infra_assume_role_policy" {
  for_each = var.addOidcUrlToIamInfraRoleMapping

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.infra_openid_connect_provider[each.key].arn] #[local.oidc_gitlab_arn]
    }
    condition {
      test     = "StringLike"
      variable = "${data.aws_iam_openid_connect_provider.infra_openid_connect_provider[each.key].url}:sub"
      values   = ["project_path:${each.value}:ref_type:branch:ref:*"]
    }
  }
}

resource "aws_iam_policy" "infra_deployment_policy" {
  for_each = var.addOidcUrlToIamInfraRoleMapping

  name        = "deployment_infra_policy_${random_string.infra_deployment_role_postfix[each.key].result}"
  path        = "/"
  description = "Policy used to deploy to AWS from GitLab."

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
            "kms:*",
            "lambda:*",
            "scheduler:*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# deployment_role_api_oidc
# ---------------------------------------------------------------------------------------------------------------------
locals {
  ecr_mappings = flatten([
    for url, mappings in var.addOidcUrlToIamECRRoleMapping : [
      for mapping in mappings : {
        url            = url
        repo_path      = mapping[0]
        ecr_name       = mapping[1]
        ecr_identifier = join("__", [url, mapping[0], mapping[1]]) # Unique identifier for each entry
      }
    ]
  ])
}

resource "random_string" "ecr_deployment_role_postfix" {
  for_each = { for mapping in local.ecr_mappings : mapping.ecr_identifier => mapping }

  length    = 4
  special   = false
  min_lower = 4
}

resource "aws_iam_role" "ecr_gitlab_ci" {
  for_each = { for mapping in local.ecr_mappings : mapping.ecr_identifier => mapping }

  name                = "deployment_role_ecr_oidc_${random_string.ecr_deployment_role_postfix[each.key].result}"
  assume_role_policy  = data.aws_iam_policy_document.ecr_assume_role_policy[each.key].json
  managed_policy_arns = [aws_iam_policy.ecr_deployment_policy[each.key].arn]
}

data "aws_iam_openid_connect_provider" "ecr_openid_connect_provider" {
  for_each = { for mapping in local.ecr_mappings : mapping.ecr_identifier => mapping }

  url = "https://${each.value.url}"

}

data "aws_iam_policy_document" "ecr_assume_role_policy" {
  for_each = { for mapping in local.ecr_mappings : mapping.ecr_identifier => mapping }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.ecr_openid_connect_provider[each.key].arn] #[local.oidc_gitlab_arn]
    }
    condition {
      test     = "StringLike"
      variable = "${data.aws_iam_openid_connect_provider.ecr_openid_connect_provider[each.key].url}:sub"
      values   = ["project_path:${each.value.repo_path}:ref_type:branch:ref:*"]
    }
  }
}

resource "aws_iam_policy" "ecr_deployment_policy" {
  for_each = { for mapping in local.ecr_mappings : mapping.ecr_identifier => mapping }

  name        = "deployment_ecr_policy_${random_string.ecr_deployment_role_postfix[each.key].result}"
  path        = "/"
  description = "Policy used to deploy to AWS from GitLab."

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ECRImagePush",
          "Effect" : "Allow",
          "Action" : [
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
          ],
          "Resource" : "arn:aws:ecr:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:repository/${each.value.ecr_name}"
        },
        {
          "Sid" : "ECRRetrieveCredentials",
          "Effect" : "Allow",
          "Action" : "ecr:GetAuthorizationToken",
          "Resource" : "*"
        }
      ]
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# deployment_role_s3_static_website_oidc
# ---------------------------------------------------------------------------------------------------------------------
locals {
  s3_static_website_mappings = flatten([
    for url, mappings in var.addOidcUrlToIamS3StaticWebsiteRoleMapping : [
      for mapping in mappings : {
        url                          = url
        repo_path                    = mapping[0]
        s3_bucket_name               = mapping[1]
        cloudfront_distribution_id   = mapping[2]
        s3_static_website_identifier = join("__", [url, mapping[0], mapping[1], mapping[2]]) # Unique identifier for each entry
      }
    ]
  ])
}

resource "random_string" "s3_static_website_deployment_role_postfix" {
  for_each = { for mapping in local.s3_static_website_mappings : mapping.s3_static_website_identifier => mapping }

  length    = 4
  special   = false
  min_lower = 4
}

resource "aws_iam_role" "s3_static_website_gitlab_ci" {
  for_each = { for mapping in local.s3_static_website_mappings : mapping.s3_static_website_identifier => mapping }

  name                = "deployment_role_s3_static_website_oidc_${random_string.s3_static_website_deployment_role_postfix[each.key].result}"
  assume_role_policy  = data.aws_iam_policy_document.s3_static_website_assume_role_policy[each.key].json
  managed_policy_arns = [aws_iam_policy.s3_static_website_deployment_policy[each.key].arn]
}

data "aws_iam_openid_connect_provider" "s3_static_website_openid_connect_provider" {
  for_each = { for mapping in local.s3_static_website_mappings : mapping.s3_static_website_identifier => mapping }

  url = "https://${each.value.url}"

}

data "aws_iam_policy_document" "s3_static_website_assume_role_policy" {
  for_each = { for mapping in local.s3_static_website_mappings : mapping.s3_static_website_identifier => mapping }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.s3_static_website_openid_connect_provider[each.key].arn] #[local.oidc_gitlab_arn]
    }
    condition {
      test     = "StringLike"
      variable = "${data.aws_iam_openid_connect_provider.s3_static_website_openid_connect_provider[each.key].url}:sub"
      values   = ["project_path:${each.value.repo_path}:ref_type:branch:ref:*"]
    }
  }
}

resource "aws_iam_policy" "s3_static_website_deployment_policy" {
  for_each = { for mapping in local.s3_static_website_mappings : mapping.s3_static_website_identifier => mapping }

  name        = "deployment_s3_static_website_policy_${random_string.s3_static_website_deployment_role_postfix[each.key].result}"
  path        = "/"
  description = "Policy used to deploy to AWS from GitLab."

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "cloudfrontinvalidationpolicy",
          "Effect" : "Allow",
          "Action" : [
            "cloudfront:CreateInvalidation",
            "cloudfront:GetInvalidation",
            "cloudfront:ListInvalidations",
          ],
          "Resource" : ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${each.value.cloudfront_distribution_id}"]
        },
        {
          "Sid" : "ListObjectsInBucket",
          "Effect" : "Allow",
          "Action" : "s3:ListBucket",
          "Resource" : ["arn:aws:s3:::${data.aws_caller_identity.current.account_id}:${each.value.s3_bucket_name}"]
        },
        {
          "Sid" : "AllObjectActions",
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
          "s3:DeleteObject"],
          "Resource" : ["arn:aws:s3:::${data.aws_caller_identity.current.account_id}:${each.value.s3_bucket_name}/*"]
        }
      ]
    }
  )
}
