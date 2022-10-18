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
