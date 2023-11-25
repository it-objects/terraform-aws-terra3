# ---------------------------------------------------------------------------------------------------------------------
# This is an example showcasing Terra3's two TF states approach for separating infra and app.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "ecs-cronjob"
}

module "terra3_examples" {
  source = "../../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"
}
