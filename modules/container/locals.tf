locals {

  # -------------------------------------------------------------------------------------------------------------------
  # Sort environment variables so terraform will not try to recreate on each plan/apply
  # -------------------------------------------------------------------------------------------------------------------
  env_vars_keys        = var.map_environment != null ? keys(var.map_environment) : var.environment != null ? [for m in var.environment : lookup(m, "name")] : []
  env_vars_values      = var.map_environment != null ? values(var.map_environment) : var.environment != null ? [for m in var.environment : lookup(m, "value")] : []
  env_vars_as_map      = zipmap(local.env_vars_keys, local.env_vars_values)
  sorted_env_vars_keys = sort(local.env_vars_keys)

  sorted_environment_vars = [
    for key in local.sorted_env_vars_keys :
    {
      name  = key
      value = lookup(local.env_vars_as_map, key)
    }
  ]

  # -------------------------------------------------------------------------------------------------------------------
  # https://www.terraform.io/docs/configuration/expressions.html#null
  # -------------------------------------------------------------------------------------------------------------------
  environment = length(local.sorted_environment_vars) > 0 ? local.sorted_environment_vars : null
}
