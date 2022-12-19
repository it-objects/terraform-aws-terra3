data "aws_region" "current_region" {} # Find region, e.g. us-east-1

#data "aws_secretsmanager_secret_version" "db_credentials" {
#  secret_id = "${local.solution_name}/db_credentials"
#}

#data "aws_ssm_parameter" "s3_solution_bucket" {
#  name = "/${local.solution_name}/s3-solution-bucket"
#}
