data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ---------------------------------------------------------------------------------------------------------------------
# security group for loadbalancer only accepting traffic from AWS Cloudfront
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "loadbalancer_sg" {
  name        = "${var.name}-loadbalancer_sg"
  vpc_id      = var.vpc_id
  description = "Security group for loadbalancer."
}

resource "aws_security_group_rule" "loadbalancer_ingress_http" {
  count = var.create_dns_and_certificates == true ? 0 : 1

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = aws_security_group.loadbalancer_sg.id
  description       = "Allow ingress traffic to ALB from Cloudfront only."
}

resource "aws_security_group_rule" "loadbalancer_ingress_https" {
  count = var.create_dns_and_certificates == true ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = aws_security_group.loadbalancer_sg.id
  description       = "ALB accepts TLS traffic on default port 443."
}

resource "aws_security_group_rule" "loadbalancer_egress_all" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ecs_task_sg.id
  security_group_id        = aws_security_group.loadbalancer_sg.id
  description              = "Allow ALB egress traffic to ECS tasks only."
}

# ---------------------------------------------------------------------------------------------------------------------
# security group for ecs task
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "ecs_task_sg" {
  name        = "${var.name}_ecs_task_sg"
  vpc_id      = var.vpc_id
  description = "Security group for an ECS task."
}

resource "aws_ssm_parameter" "ecs_task_sg_arn_param" {
  name  = "/${var.name}/sg/ecs_task_arn"
  type  = "String"
  value = aws_security_group.ecs_task_sg.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# allow ingress from lb only
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group_rule" "ecs_task_ingress" {
  type                     = "ingress"
  from_port                = 0 # all ports
  to_port                  = 0 # all ports
  protocol                 = "-1"
  source_security_group_id = aws_security_group.loadbalancer_sg.id
  security_group_id        = aws_security_group.ecs_task_sg.id
  description              = "ECS tasks may receive traffic from ALB."
}

# ---------------------------------------------------------------------------------------------------------------------
# allow ingress from other ecs task only
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group_rule" "ecs_task_ingress_self" {
  type              = "ingress"
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.ecs_task_sg.id
  description       = "ECS tasks may receive traffic from other ECS tasks."
}

# ---------------------------------------------------------------------------------------------------------------------
# egress
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-public-egress-sgr # This rule should be more restricted depending on the container requirements.
resource "aws_security_group_rule" "ecs_task_egress_all" {
  type              = "egress"
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_task_sg.id
  description       = "ECS tasks may send traffic to everywhere. This rule should be more restricted depending on the container requirements."
}

# ---------------------------------------------------------------------------------------------------------------------
# Security group that marks specific entities as valid traffic source
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "redis_access_marker_sg" {
  name        = "${var.name}_redis_access_marker_sg"
  vpc_id      = var.vpc_id
  description = "Security group for tagging ECS tasks to allow access to Redis."
}

resource "aws_ssm_parameter" "redis_access_marker_sg_arn_param" {
  name  = "/${var.name}/sg/redis_access_marker_arn"
  type  = "String"
  value = aws_security_group.redis_access_marker_sg.arn
}

resource "aws_security_group" "postgres_access_marker_sg" {
  name        = "${var.name}_postgres_access_marker_sg"
  vpc_id      = var.vpc_id
  description = "Security group for tagging ECS tasks to allow access to a database."
}

resource "aws_ssm_parameter" "postgres_access_marker_sg_arn_param" {
  name  = "/${var.name}/sg/postgres_access_marker_arn"
  type  = "String"
  value = aws_security_group.postgres_access_marker_sg.arn
}

resource "aws_security_group" "mysql_access_marker_sg" {
  name        = "${var.name}_mysql_access_marker_sg"
  vpc_id      = var.vpc_id
  description = "Security group for tagging ECS tasks to allow access to a database."
}

resource "aws_ssm_parameter" "mysql_access_marker_sg_arn_param" {
  name  = "/${var.name}/sg/mysql_access_marker_arn"
  type  = "String"
  value = aws_security_group.mysql_access_marker_sg.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Database security group that allow ingress from marked entities and bastion host (via SSM)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "mysql_db_sg" {
  name        = "${var.name}_mysql_db_sg"
  vpc_id      = var.vpc_id
  description = "Security group for MySQL allowing access by tagged instances only."
}

resource "aws_security_group_rule" "mysql_db_sg_rule" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.mysql_db_sg.id
  source_security_group_id = aws_security_group.mysql_access_marker_sg.id
  description              = "Allow ingress from marked ECS services on default MySQL port."
}

resource "aws_security_group_rule" "mysql_db_sg_rule2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.mysql_db_sg.id
  source_security_group_id = aws_security_group.bastion_host_ssm_sg.id
  description              = "Allow ingress from bastion host on default MySQL port."
}

# ---------------------------------------------------------------------------------------------------------------------
# Database security group that allow ingress from marked entities and bastion host (via SSM)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "postgres_db_sg" {
  name        = "${var.name}_postgres_db_sg"
  vpc_id      = var.vpc_id
  description = "Security group for postgres allowing access by tagged instances only."
}

resource "aws_security_group_rule" "postgres_db_sg_rule" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "TCP"
  security_group_id        = aws_security_group.postgres_db_sg.id
  source_security_group_id = aws_security_group.postgres_access_marker_sg.id
  description              = "Allow ingress from marked ECS services on default postgres port."
}

resource "aws_security_group_rule" "postgres_db_sg_rule2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "TCP"
  security_group_id        = aws_security_group.postgres_db_sg.id
  source_security_group_id = aws_security_group.bastion_host_ssm_sg.id
  description              = "Allow ingress from bastion host on default postgres port."
}

# ---------------------------------------------------------------------------------------------------------------------
# Redis security group that allow ingress from marked entities and bastion host (via SSM)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "redis_sg" {
  name        = "${var.name}_redis_db_sg"
  vpc_id      = var.vpc_id
  description = "Security group for Redis allowing access by tagged instances only."
}

resource "aws_security_group_rule" "redis_sg_rule" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "TCP"
  security_group_id        = aws_security_group.redis_sg.id
  source_security_group_id = aws_security_group.redis_access_marker_sg.id
  description              = "Allow ingress from marked ECS services on default MySQL port."
}

resource "aws_security_group_rule" "redis_sg_rule2" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "TCP"
  security_group_id        = aws_security_group.redis_sg.id
  source_security_group_id = aws_security_group.bastion_host_ssm_sg.id
  description              = "Allow ingress from bastion host on default MySQL port."
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for SSM-based Bastion Host
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "bastion_host_ssm_sg" {
  name        = "${var.name}_bastion_host_ssm_sg"
  vpc_id      = var.vpc_id
  description = "Security group for EC2 instance serving the purpose of a bastion host."
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr # required by bastion host function
resource "aws_security_group_rule" "bastion_host_ssm_sg_rule" {
  type              = "egress"
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_host_ssm_sg.id
  description       = "From bastion host users should be able to access everything."
}
