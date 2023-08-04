# tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_name
  image_tag_mutability = "IMMUTABLE"

  # enable encryption and create and use AWS managed ECR KMS key
  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "ecr_repo_policy" {
  count      = var.access_for_account_id == "" ? 0 : 1
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCrossAccountPull",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.access_for_account_id}:root"
        },
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

locals {
  aws_principals_account_ids_list = [
    for account_id in var.access_for_account_ids : format("arn:aws:iam::%s:root", account_id)
  ]
}

resource "aws_ecr_repository_policy" "ecr_repo_policy_xyz" {
  count = length(var.access_for_account_ids) > 1 ? 1 : 0

  repository = aws_ecr_repository.ecr_repo.name
  policy     = data.aws_iam_policy_document.ecr_repo_policy_xyz.json

}

data "aws_iam_policy_document" "ecr_repo_policy_xyz" {
  statement {
    sid    = "AllowCrossAccountPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.aws_principals_account_ids_list #["123456789012"]
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}
