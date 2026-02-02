# -----------------------------------------------
# Internal Service DNS Module - Locals
# -----------------------------------------------

locals {
  # Zone name: use custom or default to internal.{solution_name}.local
  zone_name = var.zone_name != "" ? var.zone_name : "internal.${var.solution_name}.local"
}
