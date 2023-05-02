# ---------------------------------------------------------------------------------------------------------------------
# This is example 3 showcasing Terra3's capabilities.
#
# Outcome: Like example 2 + with a containers AND a custom domain.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  route53_zone_id  = "<PLEASE ENTER HERE THE HOSTED ZONE ID>"
  hosted_zone_name = "<PLEASE ENTER HERE THE HOSTED ZONE NAME>"
  solution_name    = "terra3-ses"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # if set to true, domain_name or domain of zone is required
  enable_custom_domain = true

  # domain name of hosted zone to which we have full access
  # domain_name = local.custom_domain_name
  route53_zone_id = local.route53_zone_id

  # configure your environment here
  create_load_balancer = true
  create_bastion_host  = false
  create_database      = false

  # dependency: required for downloading container images
  nat = "NO_NAT"

  # configure your aws simple mail service
  create_ses           = true
  ses_domain_name      = local.hosted_zone_name
  ses_mail_from_domain = "${local.solution_name}.${local.hosted_zone_name}"
}
