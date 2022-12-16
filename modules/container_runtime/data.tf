data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.solution_name}/vpc_id"
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id.value]
  }

  tags = {
    "Tier" = "private"
  }
}

data "aws_security_group" "ecs_default_sg" {
  name = "${var.solution_name}_ecs_task_sg"
}
