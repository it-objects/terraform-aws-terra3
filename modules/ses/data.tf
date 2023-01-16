# To use an existing Route 53 domain.
data "aws_route53_zone" "main" {
  name         = var.ses_domain_name
  private_zone = false
}

data "aws_region" "current_region" {} # Find region, e.g. us-east-1
