# ---------------------------------------------------------------------------------------------------------------------
# This is an example showcasing Terra3's Lambda@Edge functions capabilities to support SPA without default error
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "lambda-at-edge"
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

module "lambda_at_edge_example" {
  source = "../../modules/lambda_at_edge"

  solution_name = local.solution_name
  # Please store the file under source_path with .mjs extension
  # E.g, viewer_request.mjs
  file_name   = "viewer_request"
  source_path = "${path.module}/lambda_at_edge_functions/"

  providers = {
    aws.useast1 = aws.useast1
  }
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  # static website configuration
  disable_custom_error_response = true

  # static website configuration for Lambda@Edge function to support SPA without default error
  s3_static_website_bucket_cf_lambda_at_edge_origin_request_arn = "${module.lambda_at_edge_example.lambda_at_edge_arn}:${module.lambda_at_edge_example.lambda_at_edge_version}"
  #  s3_static_website_bucket_cf_lambda_at_edge_viewer_request_arn = "${module.lambda_at_edge_example.lambda_at_edge_arn}:${module.lambda_at_edge_example.lambda_at_edge_version}"
  #  s3_static_website_bucket_cf_lambda_at_edge_origin_response_arn = "arn:aws:lambda:us-east-1:1234567890:function:t3-two-states-cf-admin-modify-response-header-lambda-at-edge:1"
  #  s3_static_website_bucket_cf_lambda_at_edge_viewer_response_arn = "arn:aws:lambda:us-east-1:1234567890:function:t3-two-states-cf-admin-modify-response-header-lambda-at-edge:1"

}
