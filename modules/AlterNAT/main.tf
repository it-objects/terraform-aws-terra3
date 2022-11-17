## NAT instance configuration
locals {
  initial_lifecycle_hooks = [
    {
      name                    = "NATInstanceTerminationLifeCycleHook"
      default_result          = "CONTINUE"
      heartbeat_timeout       = 180
      lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_target_arn = aws_sns_topic.alternat_topic.arn
      role_arn                = aws_iam_role.alternat_lifecycle_hook.arn
    }
  ]

  nat_instance_ingress_sgs = concat(var.ingress_security_group_ids, [aws_security_group.nat_lambda.id])

  ec2_endpoint = (
    var.enable_ec2_endpoint
    ? {
      ec2 = {
        service             = "ec2"
        private_dns_enabled = true
        subnet_ids          = var.vpc_private_subnet_ids
        tags                = { Name = "ec2-vpc-endpoint" }
      }
    }
    : {}
  )

  lambda_endpoint = (
    var.enable_lambda_endpoint
    ? {
      lambda = {
        service             = "lambda"
        private_dns_enabled = true
        subnet_ids          = var.vpc_private_subnet_ids
        tags                = { Name = "lambda-vpc-endpoint" }
      }
    }
    : {}
  )

  endpoints = merge(local.ec2_endpoint, local.lambda_endpoint)
}

resource "aws_eip" "nat_instance_eips" {
  count = length(var.vpc_public_subnet_ids)

  vpc = true
  tags = merge(var.tags, {
    "Name" = "alternat-instance-${count.index}"
  })
}

resource "aws_sns_topic" "alternat_topic" {
  name_prefix       = "alternat-topic"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_autoscaling_group" "nat_instance" {
  count = length(var.vpc_public_subnet_ids)

  name_prefix           = var.nat_instance_name_prefix
  max_size              = 1
  min_size              = 1
  desired_capacity      = 1
  max_instance_lifetime = var.max_instance_lifetime
  vpc_zone_identifier   = [var.vpc_public_subnet_ids[count.index]]

  launch_template {
    id      = aws_launch_template.nat_instance_template.id
    version = "$Latest"
  }

  dynamic "initial_lifecycle_hook" {
    for_each = local.initial_lifecycle_hooks
    content {
      name                    = initial_lifecycle_hook.value.name
      default_result          = try(initial_lifecycle_hook.value.default_result, null)
      heartbeat_timeout       = try(initial_lifecycle_hook.value.heartbeat_timeout, null)
      lifecycle_transition    = initial_lifecycle_hook.value.lifecycle_transition
      notification_metadata   = try(initial_lifecycle_hook.value.notification_metadata, null)
      notification_target_arn = try(initial_lifecycle_hook.value.notification_target_arn, null)
      role_arn                = try(initial_lifecycle_hook.value.role_arn, null)
    }
  }

  dynamic "tag" {
    for_each = merge(
      var.tags,
      { Name = "${var.nat_instance_name_prefix}${count.index}" },
      data.aws_default_tags.current.tags,
    )

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_iam_role" "alternat_lifecycle_hook" {
  name        = var.nat_instance_lifecycle_hook_role_name == "" ? null : var.nat_instance_lifecycle_hook_role_name
  name_prefix = var.nat_instance_lifecycle_hook_role_name == "" ? "alternat-lifecycle-hook-" : null

  assume_role_policy = data.aws_iam_policy_document.lifecycle_hook_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lifecycle_hook_assume_role" {
  statement {
    sid = "AutoScalingAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lifecycle_hook_policy" {
  statement {
    sid    = "alterNATLifecycleHookPermissions"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [aws_sns_topic.alternat_topic.arn]
  }
}

resource "aws_iam_role_policy" "alternat_lifecycle_hook" {
  name   = "lifecycle-publish-policy"
  policy = data.aws_iam_policy_document.lifecycle_hook_policy.json
  role   = aws_iam_role.alternat_lifecycle_hook.name
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_launch_template" "nat_instance_template" {
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 80
      encrypted   = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.nat_instance.name
  }

  image_id = var.nat_ami == "" ? data.aws_ami.amazon_linux_2.id : var.nat_ami

  instance_type = var.nat_instance_type

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nat_instance.id]
  }

  tags = var.tags

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      alterNATInstance = "true",
    })
  }

  user_data = base64encode(templatefile("${path.module}/alternat.sh.tftpl", {
    tf_eip_allocation_ids = join(",", aws_eip.nat_instance_eips[*].allocation_id),
    tf_subnet_suffix      = var.subnet_suffix,
    tf_vpc_id             = var.vpc_id
  }))
}

resource "aws_security_group" "nat_instance" {
  name_prefix = var.nat_instance_sg_name_prefix
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "nat_instance_egress" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nat_instance.id
}

resource "aws_security_group_rule" "nat_instance_ingress" {
  count = length(local.nat_instance_ingress_sgs)

  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  security_group_id        = aws_security_group.nat_instance.id
  source_security_group_id = local.nat_instance_ingress_sgs[count.index]
}


### NAT instance IAM

resource "aws_iam_instance_profile" "nat_instance" {
  name        = var.nat_instance_iam_profile_name == "" ? null : var.nat_instance_iam_profile_name
  name_prefix = var.nat_instance_iam_profile_name == "" ? "alternat-instance-" : null

  role = aws_iam_role.alternat_instance.name
  tags = var.tags
}

resource "aws_iam_role" "alternat_instance" {
  name        = var.nat_instance_iam_role_name == "" ? null : var.nat_instance_iam_role_name
  name_prefix = var.nat_instance_iam_role_name == "" ? "alternat-instance-" : null

  assume_role_policy = data.aws_iam_policy_document.nat_instance_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "nat_instance_assume_role" {
  statement {
    sid = "NATInstanceAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.alternat_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "alternat_ec2_policy" {
  statement {
    sid    = "alterNATInstancePermissions"
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceAttribute",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/alterNATInstance"
      values = [
        "true"
      ]
    }
  }

  statement {
    sid    = "alterNATDescribeRoutePermissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeRouteTables"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "alterNATModifyRoutePermissions"
    effect = "Allow"
    actions = [
      "ec2:CreateRoute",
      "ec2:ReplaceRoute"
    ]
    resources = [
      for route_table in var.private_route_table_ids
      : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:route-table/${route_table}"
    ]
  }

  statement {
    sid    = "alterNATEIPPermissions"
    effect = "Allow"

    actions = [
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "alternat_ec2" {
  name   = "alternat-policy"
  policy = data.aws_iam_policy_document.alternat_ec2_policy.json
  role   = aws_iam_role.alternat_instance.name
}

resource "aws_iam_role_policy" "alternat_additional_policies" {
  count = length(var.additional_instance_policies)

  name   = var.additional_instance_policies[count.index].policy_name
  policy = var.additional_instance_policies[count.index].policy_json
  role   = aws_iam_role.alternat_instance.name
}

## NAT Gateway used as a backup route
resource "aws_eip" "nat_gateway_eips" {
  count = length(var.vpc_public_subnet_ids)
  vpc   = true
  tags = merge(var.tags, {
    "Name" = "alternat-gateway-${count.index}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = length(var.vpc_public_subnet_ids)
  allocation_id = aws_eip.nat_gateway_eips[count.index].id
  subnet_id     = var.vpc_public_subnet_ids[count.index]
  tags = merge(var.tags, {
    Name = "alternat-${count.index}"
  })
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "vpc_endpoint" {
  count = length(local.endpoints) > 0 ? 1 : 0

  name_prefix = "ec2-vpc-endpoints-"
  description = "Allow TLS from the VPC CIDR to the AWS API."
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

module "vpc_endpoints" {
  count = length(local.endpoints) > 0 ? 1 : 0

  source             = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version            = "~> 3.14.0"
  vpc_id             = var.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoint[0].id]
  endpoints          = local.endpoints
  tags               = var.tags
}

data "aws_default_tags" "current" {}
