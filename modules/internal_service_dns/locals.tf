# -----------------------------------------------
# Internal Service DNS Module - Locals
# -----------------------------------------------

locals {
  # Zone name: use custom or default to internal.{solution_name}.local
  zone_name = var.zone_name != "" ? var.zone_name : "internal.${var.solution_name}.local"
  # Cloud Map gets a subdomain to avoid Route53 zone conflict in the same VPC
  cloud_map_zone_name = "svc.${local.zone_name}"
}
