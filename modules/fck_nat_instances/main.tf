# ---------------------------------------------------------------------------------------------------------------------
# Create FCKNAT instance(s) (as alternative to NAT gateway and NAT instance)
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-public-egress-sgr
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group" "main" {
  name        = var.solution_name
  description = "Used in ${var.solution_name} instance of ITO FCK-NAT in subnet"
  vpc_id      = data.aws_vpc.main.id

  egress {
    description      = "For FCK NAT instance allow all outbound traffic."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "For FCK NAT instance allow all inbound traffic from private subnets."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_subnets_cidr_blocks # TODO can we make it only the private subnets?
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic IPs of the latest FCK_NAT
#---------------------------------------------------------------------------------------------------------------------
#Create an Elastic IP and associate it with the latest instance
resource "aws_eip" "main" {
  count = (var.enable_fcknat_eip && length(var.azs) > 0) ? length(var.azs) : 0

  domain = "vpc"
}

resource "aws_network_interface" "public_subnets" {
  count = (var.enable_fcknat_eip && length(var.azs) > 0) ? length(var.azs) : 0

  description       = "${var.solution_name} static public ENI"
  subnet_id         = var.public_subnets[count.index]
  security_groups   = [aws_security_group.main.id]
  source_dest_check = false


  tags = {
    Name = "${var.solution_name}-fck-nat"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI of the latest FCK_NAT
# ---------------------------------------------------------------------------------------------------------------------
locals {
  is_arm = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.fcknat_instance_type[0]))
}

data "aws_ami" "main" {

  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = [local.is_arm ? "arm64" : "x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create FCK_NAT launch template
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_launch_template" "main" {
  # count defines a loop along all AZ's
  count = length(var.azs)

  name_prefix = "${var.solution_name}-fck-nat-instance-template-${var.azs[count.index]}-"
  image_id    = data.aws_ami.main.id

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  network_interfaces {
    description                 = "${var.solution_name} ephemeral public ENI"
    subnet_id                   = var.public_subnets[count.index]
    associate_public_ip_address = true
    security_groups             = concat([aws_security_group.main.id], var.extra_security_groups)
  }

  instance_type = var.fcknat_instance_type[0]

  # Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    TERRAFORM_ENI_ID = (var.enable_fcknat_eip && length(var.azs) > 0) ? aws_network_interface.public_subnets[count.index].id : ""
    TERRAFORM_EIP_ID = (var.enable_fcknat_eip && length(var.azs) > 0) ? aws_eip.main[count.index].id : ""
  }))

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_size = "8"
      volume_type = "gp3"
    }
  }

  description = "Launch template for NAT instance ${var.solution_name}"

  tags = {
    Name = "${var.solution_name}-fck-nat-instance-${var.azs[count.index]}"
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value

      tags = merge({ Name = "${var.solution_name}-fck-nat-instance-${var.azs[count.index]}" }, var.tags)
    }
  }

  lifecycle {
    # Required to redeploy without an outage.
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create FCK_NAT autoscaling group for every public subnet
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "main" {
  # count defines a loop along all AZ's
  count = length(var.azs)

  name_prefix         = "${var.solution_name}-fck-nat-asg-${var.azs[count.index]}-"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.public_subnets[count.index]]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.fcknat_use_spot_instance ? 0 : 1
      on_demand_percentage_above_base_capacity = var.fcknat_use_spot_instance ? 0 : 100
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.main[count.index].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.fcknat_instance_type
        content {
          instance_type = override.value
        }
      }
    }
  }

  # Tag for name
  tag {
    key                 = "Name"
    value               = "${var.solution_name}-fck-nat-instance-${var.azs[count.index]}"
    propagate_at_launch = true
  }

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "main" {
  name_prefix = "${var.solution_name}-fck-nat-instance-"
  role        = aws_iam_role.main.name

  tags = var.tags
}

resource "aws_iam_role" "main" {
  name_prefix        = "${var.solution_name}-fck-nat-instance-"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.main.name
}

resource "aws_iam_policy" "main" {
  name   = var.solution_name
  policy = data.aws_iam_policy_document.main.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

locals {
  fck_nat_eip_allocation_ids = [for eip in aws_eip.main : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/${eip.id}"]
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "main" {
  statement {
    sid    = "ManageNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/Name"
      values   = ["${var.solution_name}-fck-nat*"]
    }
  }

  dynamic "statement" {
    for_each = (var.enable_fcknat_eip && length(var.azs) > 0) ? ["x"] : []

    content {
      sid    = "ManageEIPAllocation"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = local.fck_nat_eip_allocation_ids

    }
  }

  dynamic "statement" {
    for_each = length(var.azs) != 0 ? ["x"] : []

    content {
      sid    = "ManageEIPNetworkInterface"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      ]
      condition {
        test     = "StringLike"
        variable = "ec2:ResourceTag/Name"
        values   = ["${var.solution_name}-fck-nat*"]
      }
    }
  }
}
