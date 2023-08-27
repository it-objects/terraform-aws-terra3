# ---------------------------------------------------------------------------------------------------------------------
# This is an example showcasing Terra3's two TF states approach for separating infra and app.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "t3-two-states"
}

module "terra3_examples" {
  source = "../../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  create_s3_solution_bucket = true
  s3_solution_bucket_cf_behaviours = [
    {
      s3_solution_bucket_cloudfront_path = "/media_attachments/*"
    }
  ]

  enable_cloudfront_url_signing_for_solution_bucket = true

  # In single TF state setup, these are being calculated. Otherwise, these need to be given
  # to indicate Cloudfront, that it should forward multiple directories to containers.
  custom_elb_cf_path_patterns = ["/api/*", "/custom/*"]
}
