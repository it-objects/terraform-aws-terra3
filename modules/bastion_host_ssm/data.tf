# ---------------------------------------------------------------------------------------------------------------------
# Determine security groups
# ---------------------------------------------------------------------------------------------------------------------
data "aws_security_group" "bastion_host_ssm_sg" {
  name = "${var.environment_name}_bastion_host_ssm_sg"
}
