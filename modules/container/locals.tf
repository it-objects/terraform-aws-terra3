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
  environment = length(local.sorted_environment_vars) > 0 ? local.sorted_environment_vars : null

  # -------------------------------------------------------------------------------------------------------------------
  # Sort secrets so terraform will not try to recreate on each plan/apply
  # -------------------------------------------------------------------------------------------------------------------
  secrets_keys        = var.map_secrets != null ? keys(var.map_secrets) : var.secrets != null ? [for m in var.secrets : lookup(m, "name")] : []
  secrets_values      = var.map_secrets != null ? values(var.map_secrets) : var.secrets != null ? [for m in var.secrets : lookup(m, "value")] : []
  secrets_as_map      = zipmap(local.secrets_keys, local.secrets_values)
  sorted_secrets_keys = sort(local.secrets_keys)

  sorted_secrets = [
    for key in local.sorted_secrets_keys :
    {
      name      = key
      valueFrom = lookup(local.secrets_as_map, key)
    }
  ]
  secrets = length(local.sorted_secrets) > 0 ? local.sorted_secrets : null
}
