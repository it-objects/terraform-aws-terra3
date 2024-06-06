data "aws_ssm_parameter" "ebs_volume_names" {
  name  = "/${var.solution_name}/app_components/ebs_volume_names"
}

output "ebs_volume_name" {
  value = ["my_app_component-Service-Volume","my_app_component_2-Service-Volume"] #[data.aws_ssm_parameter.ebs_volume_names.value]
  sensitive = true
}