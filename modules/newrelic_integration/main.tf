resource "aws_iam_role" "newrelic_infra_integration" {
  name = "NewRelicInfrastructureIntegration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::754728514883:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.newrelic_account_id
          }
        }
      },
    ]
  })

  inline_policy {
    name = "NewRelicBudgetRead"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "budgets:ViewBudget",
          "config:BatchGetAggregateResourceConfig",
          "config:BatchGetResourceConfig",
          "config:Deliver*",
          "config:Describe*",
          "config:Get*",
          "config:List*",
          "config:SelectAggregateResourceConfig",
          "config:SelectResourceConfig",
          "tag:GetResources",
          "tag:GetTagValues",
          "tag:DescribeReportCreation",
          "tag:GetTagKeys",
          "tag:GetComplianceSummary"
        ]
        Effect   = "Allow"
        Resource = "*"
      }]
    })
  }
}
