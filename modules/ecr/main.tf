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

# Create the list of account ids, works for both the parameters => ID and IDs.
locals {
  aws_principals_account_id_list = length(var.access_for_account_id) > 0 ? [
    "arn:aws:iam::${var.access_for_account_id}:root"
  ] : []

  aws_principals_account_ids_list = length(var.access_for_account_ids) > 0 ? [
    for account_id in var.access_for_account_ids : format("arn:aws:iam::%s:root", account_id)
  ] : []

  all_account_ids = concat(local.aws_principals_account_id_list, local.aws_principals_account_ids_list)

}

resource "aws_ecr_repository_policy" "ecr_repo_policy" {
  count = length(local.all_account_ids) > 0 ? 1 : 0

  repository = aws_ecr_repository.ecr_repo.name
  policy     = data.aws_iam_policy_document.ecr_repo_policy_xyz.json

}

data "aws_iam_policy_document" "ecr_repo_policy_xyz" {
  statement {
    sid    = "AllowCrossAccountPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.all_account_ids #["123456789012"]
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}
