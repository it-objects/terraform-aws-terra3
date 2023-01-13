provider "aws" {
  region = "eu-central-1"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true

  # skip_requesting_account_id should be disabled to generate valid ARN in apigatewayv2_api_execution_arn
  skip_requesting_account_id = false

  default_tags {
    tags = {
      "terra3.io/project" = "terra3-examples"
      Environment         = "qa"
      Terraform           = "true"
    }
  }
}
