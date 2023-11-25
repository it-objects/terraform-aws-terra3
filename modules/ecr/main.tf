resource "aws_ecr_repository" "ecr_repo" {
  count                = length(var.create_ecr_with_names)
  name                 = element(var.create_ecr_with_names, count.index) #var.create_ecr_with_names[count.index]
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
  aws_principals_account_id_list_1 = length(var.access_for_account_id) > 0 ? [var.access_for_account_id] : [] # to make sure when it is not provided it should pass empty list.
  all_account_ids                  = concat(local.aws_principals_account_id_list_1, var.access_for_account_ids)
}

resource "aws_ecr_repository_policy" "ecr_repo_policy" {
  count = length(local.all_account_ids) > 0 ? length(var.create_ecr_with_names) : 0

  repository = aws_ecr_repository.ecr_repo[count.index].name
  policy     = data.aws_iam_policy_document.ecr_repo_policy_xyz.json

}

data "aws_iam_policy_document" "ecr_repo_policy_xyz" {
  statement {
    sid    = "AllowCrossAccountPull"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        for account_id in local.all_account_ids : format("arn:aws:iam::%s:root", account_id)
      ]
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}
