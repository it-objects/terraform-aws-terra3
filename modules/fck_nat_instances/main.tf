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
    cidr_blocks = var.private_subnets_cidr_blocks # TODO can we make it only the public subnets?
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

resource "aws_eip_association" "eip_assoc" {
  count = (var.enable_fcknat_eip && length(var.azs) > 0) ? length(var.azs) : 0

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

  # for the time of free tier (end of May 2020), use t2.micro for the first AZ, for the rest use the one defined in main.tf
  instance_type = var.fcknat_instance_type[0]

  # Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode("${path.module}/templates/user_data.sh")

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

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.main.name
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
    for_each = (var.enable_fcknat_eip && length(var.azs) > 0) ? ["x"] : []

    content {
      sid    = "ManageEIPAllocation"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [ # TODO update the below command to allow for all the eip allocation ids
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
        #"arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/${aws_eip.main.allocation_id}"
      ]
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
        test     = "StringEquals"
        variable = "ec2:ResourceTag/Name"
        values   = [var.solution_name]
      }
    }
  }
}
