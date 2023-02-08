# ---------------------------------------------------------------------------------------------------------------------
# This is example 1 showcasing Terra3's capabilities.
#
# Outcome: Environment with S3 bucket serving a static website via Cloudfront and a static Cloudfront URL
# Remarks: This is the most minimal solution which runs without further effort out-of-the-box in an empty
#          AWS account.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "terra3-example1"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true
  nat                  = "NO_NAT" # default value
}
