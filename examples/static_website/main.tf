# ---------------------------------------------------------------------------------------------------------------------
# This is an example of a Static Website Deployment showcasing Terra3's capabilities.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "static-website"
  domain_name     = "<PLEASE ENTER HERE THE FULL DOMAIN NAME>"
  #route53_zone_id = "<PLEASE ENTER HERE THE HOSTED ZONE ID>"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true
  enable_account_level_resources = false

  # configure your environment here
  create_load_balancer = false

  # dependency: required for downloading container images
  nat = "NO_NAT"

  # if set to true, domain_name or domain of zone is required
  enable_custom_domain = true
  create_subdomain     = false
  domain_name          = local.domain_name
  #route53_zone_id      = local.route53_zone_id

  enable_vpc_s3_endpoint = false

  # static website configuration
  add_default_index_html        = false
  disable_custom_error_response = true

  # static website configuration for Lambda@Edge function to support SPA without default error
  s3_static_website_bucket_cf_lambda_at_edge_origin_request_arn = "${module.lambda_at_edge_example.lambda_at_edge_arn}:${module.lambda_at_edge_example.lambda_at_edge_version}"
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

module "lambda_at_edge_example" {
  source  = "it-objects/terra3/aws//modules/lambda_at_edge"
  version = "v1.32.0"

  solution_name = "${local.solution_name}-test"
  # Please store the file under source_path with .mjs extension
  # E.g, origin_request.mjs
  file_name   = "origin_request"
  source_path = "${path.module}/lambda_at_edge_functions/"

  providers = {
    aws.useast1 = aws.useast1
  }
}

resource "aws_s3_object" "static_website_index_file" {
  key                    = "index.html"
  bucket                 = module.terra3_examples.s3_static_website_name
  source                 = "${path.module}/index.html"
  content_type           = "text/html"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/index.html")
}

resource "aws_s3_object" "static_website_image_file" {
  key                    = "light.jpg"
  bucket                 = module.terra3_examples.s3_static_website_name
  source                 = "${path.module}/light.jpg"
  content_type           = "text/html"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/light.jpg")
}
