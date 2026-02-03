# -----------------------------------------------
# EC2 Docker Workload Module - Main
# -----------------------------------------------

# -----------------------------------------------
# Security Group (if not provided)
# -----------------------------------------------

resource "aws_security_group" "default" {
  count       = length(var.security_group_ids) == 0 ? 1 : 0
  name_prefix = "${var.solution_name}-${var.instance_name}-"
  description = "Security group for ${var.solution_name} ${var.instance_name} Docker workload"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  tags = merge(
    local.common_tags,
    {
      Name = "${var.solution_name}-${var.instance_name}-sg"
    }
  )
}

# -----------------------------------------------
# Security Group Ingress Rules
# -----------------------------------------------

# Allow all ingress traffic (will be gated by network placement)
resource "aws_security_group_rule" "all_ingress" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.default[0].id
  description       = "Allow all inbound traffic from self for internal communication"

  lifecycle {
    create_before_destroy = true
  }
}

# Allow ingress from bastion host on mapped ports (if bastion exists)
resource "aws_security_group_rule" "bastion_to_mapped_ports" {
  # Only create if: (1) we have port mappings, (2) using module-created SG, (3) bastion SG exists
  count = try(
    length(var.port_mappings) > 0 && length(var.security_group_ids) == 0 ? length(var.port_mappings) : 0,
    0
  )

  type                     = "ingress"
  from_port                = var.port_mappings[count.index].hostPort
  to_port                  = var.port_mappings[count.index].hostPort
  protocol                 = var.port_mappings[count.index].protocol
  source_security_group_id = try(data.aws_security_group.bastion_host_ssm_sg.id, null)
  security_group_id        = aws_security_group.default[0].id
  description              = "Allow inbound traffic from bastion host on port ${var.port_mappings[count.index].hostPort}/${var.port_mappings[count.index].protocol}"

  # Skip if bastion security group lookup fails (bastion not deployed)
  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(data.aws_security_group.bastion_host_ssm_sg.id != null, false)
      error_message = "Bastion host security group not found. Skipping bastion ingress rule."
    }
  }
}

# Allow ingress from ECS tasks on mapped ports (if ecs service exists)
resource "aws_security_group_rule" "ecs_task_to_mapped_ports" {
  # Only create if: (1) we have port mappings, (2) using module-created SG, (3) ECS SG exists
  count = try(
    length(var.port_mappings) > 0 && length(var.security_group_ids) == 0 ? length(var.port_mappings) : 0,
    0
  )

  type                     = "ingress"
  from_port                = var.port_mappings[count.index].hostPort
  to_port                  = var.port_mappings[count.index].hostPort
  protocol                 = var.port_mappings[count.index].protocol
  source_security_group_id = try(data.aws_security_group.ecs_task_sg.id, null)
  security_group_id        = aws_security_group.default[0].id
  description              = "Allow inbound traffic from ECS tasks on port ${var.port_mappings[count.index].hostPort}/${var.port_mappings[count.index].protocol}"

  # Skip if ECS security group lookup fails (ECS not deployed)
  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(data.aws_security_group.ecs_task_sg.id != null, false)
      error_message = "ECS task security group not found. Skipping ECS ingress rule."
    }
  }
}

# Allow egress to bastion host on mapped ports (if bastion exists)
resource "aws_security_group_rule" "egress_to_bastion_host" {
  count = try(
    length(var.port_mappings) > 0 && length(var.security_group_ids) == 0 ? length(var.port_mappings) : 0,
    0
  )

  type                     = "egress"
  from_port                = var.port_mappings[count.index].hostPort
  to_port                  = var.port_mappings[count.index].hostPort
  protocol                 = var.port_mappings[count.index].protocol
  source_security_group_id = try(data.aws_security_group.bastion_host_ssm_sg.id, null)
  security_group_id        = aws_security_group.default[0].id
  description              = "Allow outbound traffic to bastion host on port ${var.port_mappings[count.index].hostPort}/${var.port_mappings[count.index].protocol}"

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(data.aws_security_group.bastion_host_ssm_sg.id != null, false)
      error_message = "Bastion host security group not found. Skipping bastion egress rule."
    }
  }
}

# Allow egress to ECS tasks on mapped ports (if ECS service exists)
resource "aws_security_group_rule" "egress_to_ecs_task" {
  count = try(
    length(var.port_mappings) > 0 && length(var.security_group_ids) == 0 ? length(var.port_mappings) : 0,
    0
  )

  type                     = "egress"
  from_port                = var.port_mappings[count.index].hostPort
  to_port                  = var.port_mappings[count.index].hostPort
  protocol                 = var.port_mappings[count.index].protocol
  source_security_group_id = try(data.aws_security_group.ecs_task_sg.id, null)
  security_group_id        = aws_security_group.default[0].id
  description              = "Allow outbound traffic to ECS tasks on port ${var.port_mappings[count.index].hostPort}/${var.port_mappings[count.index].protocol}"

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = try(data.aws_security_group.ecs_task_sg.id != null, false)
      error_message = "ECS task security group not found. Skipping ECS egress rule."
    }
  }
}

# Allow egress to self for internal communication
resource "aws_security_group_rule" "egress_to_self" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.default[0].id
  description       = "Allow all outbound traffic to self for internal communication"

  lifecycle {
    create_before_destroy = true
  }
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr # Allow egress for DNS (required for service discovery and AWS API calls)
resource "aws_security_group_rule" "egress_dns" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default[0].id
  description       = "Allow egress for DNS (required for service discovery and AWS API calls)"

  lifecycle {
    create_before_destroy = true
  }
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr # Allow egress for HTTPS (required for AWS API calls and package downloads)
resource "aws_security_group_rule" "egress_https" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default[0].id
  description       = "Allow egress for HTTPS (required for AWS API calls and package downloads)"

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------
# KMS Key for CloudWatch Logs Encryption
# -----------------------------------------------

resource "aws_kms_key" "logs" {
  description             = "KMS key for ${var.solution_name} ${var.instance_name} CloudWatch logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.solution_name}-${var.instance_name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# -----------------------------------------------
# CloudWatch Log Group (Encrypted)
# -----------------------------------------------

resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/${var.solution_name}/ec2_docker_workload/${var.instance_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn

  tags = local.common_tags
}

# -----------------------------------------------
# User Data Script
# -----------------------------------------------

locals {
  # Expected device names for volumes (for formatting and mounting)
  volume_device_names = [for vol in var.ebs_volumes : trimprefix(vol.device_name, "/dev/")]

  user_data_script = base64gzip(templatefile("${path.module}/user_data.sh", {
    docker_image_uri     = var.docker_image_uri
    docker_env_vars      = local.docker_env_vars
    docker_port_args     = local.docker_port_args
    docker_volume_mounts = local.docker_volume_mounts
    instance_name        = var.instance_name
    log_group_name       = aws_cloudwatch_log_group.docker_logs.name
    solution_name        = var.solution_name
    aws_region           = data.aws_region.current.name
    expected_devices     = join(" ", local.volume_device_names)
  }))
}

# -----------------------------------------------
# Launch Template
# -----------------------------------------------

resource "aws_launch_template" "docker_workload" {
  name_prefix            = "${var.solution_name}-${var.instance_name}-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = local.security_groups

  # IMDSv2 Enforcement
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # IAM Instance Profile
  iam_instance_profile {
    arn = aws_iam_instance_profile.docker_workload_profile.arn
  }

  # Root Volume Configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Note: Persistent EBS volumes are created as separate aws_ebs_volume resources
  # and attached via aws_volume_attachment to support persistence across instance restarts

  # User Data for Docker initialization
  user_data = local.user_data_script

  # Tag volumes
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        LaunchTemplate = "${var.solution_name}-${var.instance_name}-template"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.common_tags
  }

  lifecycle {
    create_before_destroy = true
    # Prevent recreating instances when a new AMI is available
    ignore_changes = [image_id]
  }
}

# -----------------------------------------------
# Auto Scaling Group for Persistent Workload
# -----------------------------------------------
# ASG with min_size=1, max_size=1, desired_capacity=1
# Ensures automatic recovery if instance fails while maintaining single instance

resource "aws_autoscaling_group" "docker_workload" {
  name             = "${var.solution_name}-${var.instance_name}-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = split(",", data.aws_ssm_parameter.private_subnets.value)

  launch_template {
    id      = aws_launch_template.docker_workload.id
    version = "$Latest"
  }

  health_check_grace_period = 300
  default_cooldown          = 300
  health_check_type         = "EC2"

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.min_healthy_percentage
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_role_policy.cloudwatch_logs,
    aws_iam_role_policy_attachment.ssm_managed_instance_core
  ]
}

# -----------------------------------------------
# Persistent EBS Volumes (for Docker container mounts)
# -----------------------------------------------
# Create volumes that persist across instance termination
# Only volumes with delete_on_termination = false are created here
resource "aws_ebs_volume" "persistent" {
  for_each = {
    for idx, vol in local.persistent_volumes :
    idx => vol
  }

  availability_zone = local.volume_az
  size              = each.value.size
  type              = each.value.volume_type
  encrypted         = true
  # Use AWS-managed aws/ebs key (default) - no custom KMS key needed
  # The aws/ebs key allows all EC2 instances to attach encrypted volumes

  tags = merge(
    local.common_tags,
    {
      Name             = "${var.solution_name}-${var.instance_name}-volume-${each.key}"
      DeviceName       = each.value.device_name
      MountPath        = each.value.mount_path
      Persistent       = "true"
      WorkloadInstance = var.instance_name
    }
  )
}

# -----------------------------------------------
# Route53 Internal DNS for Service Discovery
# -----------------------------------------------

# Private hosted zone for internal service discovery
# Create zone if internal DNS is enabled and no zone ID is provided
# Once created, the zone persists and is reused by other workloads
# DNS A record pointing to the current running instance
resource "aws_route53_record" "workload" {
  count   = var.enable_internal_dns ? 1 : 0
  zone_id = try(data.aws_ssm_parameter.internal_dns_zone_id[0].value, "")
  name    = local.internal_dns_record_name
  type    = "A"
  ttl     = 60
  # Points to the current running instance IP
  records = [try(data.aws_instances.docker_workload.private_ips[0], "127.0.0.1")]
}

# -----------------------------------------------
# SSM Parameters for Service Discovery
# -----------------------------------------------

resource "aws_ssm_parameter" "security_group_id" {
  name      = "${local.ssm_param_prefix}/security_group_id"
  type      = "String"
  value     = local.security_groups[0]
  overwrite = true

  tags = local.common_tags
}

resource "aws_ssm_parameter" "log_group_name" {
  name      = "${local.ssm_param_prefix}/log_group_name"
  type      = "String"
  value     = aws_cloudwatch_log_group.docker_logs.name
  overwrite = true

  tags = local.common_tags
}

# Store ASG name for reference
resource "aws_ssm_parameter" "asg_name" {
  name      = "${local.ssm_param_prefix}/asg_name"
  type      = "String"
  value     = aws_autoscaling_group.docker_workload.name
  overwrite = true

  tags = local.common_tags
}

# -----------------------------------------------
# AWS Backup Configuration (conditional)
# -----------------------------------------------

# Backup Vault for storing snapshots
resource "aws_backup_vault" "docker_workload" {
  count         = var.enable_backup ? 1 : 0
  name          = "${var.solution_name}-${var.instance_name}-vault"
  kms_key_arn   = aws_kms_key.backup[0].arn
  force_destroy = false

  tags = merge(
    local.common_tags,
    {
      Purpose = "ECS Docker Workload Backup"
    }
  )
}

# KMS Key for encrypting backups
resource "aws_kms_key" "backup" {
  count                   = var.enable_backup ? 1 : 0
  description             = "KMS key for ${var.solution_name} ${var.instance_name} backup vault"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Purpose = "Backup Encryption"
    }
  )
}

resource "aws_kms_alias" "backup" {
  count         = var.enable_backup ? 1 : 0
  name          = "alias/${var.solution_name}-${var.instance_name}-backup"
  target_key_id = aws_kms_key.backup[0].key_id
}

# IAM Role for AWS Backup Service
resource "aws_iam_role" "backup_service_role" {
  count       = var.enable_backup ? 1 : 0
  name_prefix = "${var.solution_name}-${var.instance_name}-backup-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS managed policy for backup service
resource "aws_iam_role_policy_attachment" "backup_service_policy" {
  count      = var.enable_backup ? 1 : 0
  role       = aws_iam_role.backup_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Additional policy for EBS snapshot permissions
resource "aws_iam_role_policy" "backup_ebs_policy" {
  count       = var.enable_backup ? 1 : 0
  name_prefix = "backup-ebs-"
  role        = aws_iam_role.backup_service_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:CopySnapshot",
          "ec2:CreateTags"
        ]
        Resource = concat(
          [for vol in var.ebs_volumes : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*"],
          ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances"
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.backup[0].arn
      }
    ]
  })
}

# Backup Plan
resource "aws_backup_plan" "docker_workload" {
  count = var.enable_backup ? 1 : 0
  name  = "${var.solution_name}-${var.instance_name}-backup-plan"

  rule {
    rule_name                = "${var.instance_name}-scheduled-backup"
    target_vault_name        = aws_backup_vault.docker_workload[0].name
    schedule                 = var.backup_schedule
    enable_continuous_backup = false
    recovery_point_tags = merge(
      local.common_tags,
      {
        BackupPlan = "${var.instance_name}-backup-plan"
      }
    )

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }

  tags = local.common_tags
}

# Backup Selection for persistent EBS volumes
# Only volumes with delete_on_termination = false are included
resource "aws_backup_selection" "docker_workload" {
  count        = var.enable_backup && length([for vol in var.ebs_volumes : vol if vol.delete_on_termination == false]) > 0 ? 1 : 0
  name         = "${var.solution_name}-${var.instance_name}-volumes"
  plan_id      = aws_backup_plan.docker_workload[0].id
  iam_role_arn = aws_iam_role.backup_service_role[0].arn

  resources = []

  selection_tag {
    key   = "Solution"
    value = var.solution_name
    type  = "STRINGEQUALS"
  }

  selection_tag {
    key   = "WorkloadInstance"
    value = var.instance_name
    type  = "STRINGEQUALS"
  }

  depends_on = [
    aws_iam_role_policy_attachment.backup_service_policy,
    aws_iam_role_policy.backup_ebs_policy
  ]
}

# -----------------------------------------------
# Lambda for Automatic Route53 Updates
# -----------------------------------------------
# Updates Route53 DNS record when ASG launches/replaces instances

resource "aws_iam_role" "route53_updater_lambda" {
  count       = var.enable_internal_dns ? 1 : 0
  name_prefix = "${var.solution_name}-${var.instance_name}-route53-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "route53_updater_lambda" {
  count       = var.enable_internal_dns ? 1 : 0
  name_prefix = "route53-updater-"
  role        = aws_iam_role.route53_updater_lambda[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = try(data.aws_route53_zone.internal[0].arn, "arn:aws:route53:::hostedzone/*")
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        #tfsec:ignore:aws-iam-no-policy-wildcards # Lambda needs to create log groups with dynamic names
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

#tfsec:ignore:aws-lambda-enable-tracing # Route53 updater is low-criticality automation, no tracing needed
resource "aws_lambda_function" "route53_updater" {
  count            = var.enable_internal_dns ? 1 : 0
  filename         = data.archive_file.route53_updater_lambda[0].output_path
  function_name    = "${var.solution_name}-${var.instance_name}-route53-updater"
  role             = aws_iam_role.route53_updater_lambda[0].arn
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.route53_updater_lambda[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      ZONE_ID       = local.internal_dns_zone_id
      RECORD_NAME   = local.internal_dns_record_name
      ASG_NAME      = aws_autoscaling_group.docker_workload.name
      SOLUTION_NAME = var.solution_name
      INSTANCE_NAME = var.instance_name
    }
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.route53_updater_lambda]
}

data "archive_file" "route53_updater_lambda" {
  count       = var.enable_internal_dns ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/lambda_route53_updater.zip"

  source {
    content  = file("${path.module}/route53_updater.py")
    filename = "index.py"
  }
}

# EventBridge rule to trigger Lambda when ASG launches instances
resource "aws_cloudwatch_event_rule" "asg_instance_launch" {
  count          = var.enable_internal_dns ? 1 : 0
  name_prefix    = "${var.solution_name}-${var.instance_name}-asg-launch-"
  description    = "Trigger Route53 update when ASG launches instances"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running"]
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "asg_instance_launch_lambda" {
  count     = var.enable_internal_dns ? 1 : 0
  rule      = aws_cloudwatch_event_rule.asg_instance_launch[0].name
  arn       = aws_lambda_function.route53_updater[0].arn
  target_id = "route53_updater"
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enable_internal_dns ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.route53_updater[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_instance_launch[0].arn
}
