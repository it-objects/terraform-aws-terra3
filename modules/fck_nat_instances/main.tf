locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
}

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
    cidr_blocks = var.private_subnets_cidr_blocks
  }
}

resource "aws_network_interface" "private_main" {
  #count = length(var.azs)

  # count defines a loop along all AZ's
  count = (var.update_route_table && length(var.azs) > 0) ? length(var.azs) : 0

  description       = "${var.solution_name} static private ENI"
  subnet_id         = var.private_subnets[count.index]
  security_groups   = [aws_security_group.main.id]
  source_dest_check = false

  tags = merge({ Name = var.solution_name }, var.tags)
}

resource "aws_route" "main" {
  for_each = var.update_route_tables || var.update_route_table ? merge(var.route_tables_ids, var.route_table_id != null ? { RESERVED_FKC_NAT = var.route_table_id } : {}) : {}

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.private_main[*].id
}

# ---------------------------------------------------------------------------------------------------------------------
# Elastic IPs of the latest FCK_NAT
#---------------------------------------------------------------------------------------------------------------------
#Create an Elastic IP and associate it with the latest instance
resource "aws_eip" "main" {
  count  = length(var.azs)
  domain = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  count = length(var.azs)

  allocation_id        = aws_eip.main[count.index].id
  network_interface_id = data.aws_network_interfaces.public_enis[count.index].ids[0]
}

# Filter Network Interfaces Using the public subnet-is and the description of the network interface
data "aws_network_interfaces" "public_enis" {
  count = length(var.azs)

  filter {
    name   = "subnet-id"
    values = [var.public_subnets[count.index]]
  }

  filter {
    name   = "description"
    values = ["${var.solution_name} ephemeral public ENI"]
  }

  depends_on = [aws_autoscaling_group.main, aws_launch_template.main] # Ensures ASG is created first
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI of the latest FCK_NAT
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "main" {
  count = var.ami_id != null ? 0 : 1

  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
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

  #checkov:skip=CKV_AWS_88:NAT instances must have a public IP.
  name_prefix = "${var.solution_name}-fck-nat-instance-template-${var.azs[count.index]}-"
  image_id    = local.ami_id

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  network_interfaces {
    description                 = "${var.solution_name} ephemeral public ENI"
    subnet_id                   = var.public_subnets[count.index]
    associate_public_ip_address = true
    security_groups             = concat([aws_security_group.main.id], var.extra_security_groups)
  }

  # for the time of free tier (end of May 2020), use t2.micro for the first AZ, for the rest use the one defined in main.tf
  instance_type = var.nat_instance_types[0]

  # Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    TERRAFORM_ENI_ID = ""
    TERRAFORM_EIP_ID = ""
    ##TERRAFORM_ENI_ID = length(data.aws_network_interfaces.public_enis[count.index].ids[0]) > 0 ? data.aws_network_interfaces.public_enis[count.index].ids[0] : ""
    ##TERRAFORM_EIP_ID = length(var.eip_allocation_ids) != 0 ? var.eip_allocation_ids[count.index] : ""
    #TERRAFORM_ENI_ID = aws_network_interface.main[count.index].id
    #TERRAFORM_EIP_ID = aws_eip.main[*].allocation_id
  }))

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_size = "8"
      volume_type = "gp3"
    }
  }

  dynamic "instance_market_options" {
    for_each = var.use_spot_instances ? ["x"] : []

    content {
      market_type = "spot"
    }
  }

  description = "Launch template for NAT instance ${var.solution_name}"
  tags = {
    Name = "${var.solution_name}-fck-nat-instance"
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

  launch_template {
    id      = aws_launch_template.main[count.index].id
    version = "$Latest"
  }

  # Tag for name
  tag {
    key                 = "Name"
    value               = "${var.solution_name}-nat-instance-${var.azs[count.index]}"
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
  name_prefix = "${var.solution_name}-"
  role        = aws_iam_role.main.name

  tags = var.tags
}

resource "aws_iam_role" "main" {
  name_prefix        = "${var.solution_name}-"
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

resource "aws_iam_policy" "main" {
  name   = var.solution_name
  policy = data.aws_iam_policy_document.main.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards # could be more restrictive
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
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [var.solution_name]
    }
  }

  dynamic "statement" {
    for_each = length(var.eip_allocation_ids) != 0 ? ["x"] : []

    content {
      sid    = "ManageEIPAllocation"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/${var.eip_allocation_ids[0]}",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.eip_allocation_ids) != 0 ? ["x"] : []

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
        test     = "StringEquals"
        variable = "ec2:ResourceTag/Name"
        values   = [var.solution_name]
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.main.name
}
