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

resource "aws_network_interface" "public_subnets" {
  count = (var.enable_fcknat_eip && length(var.azs) > 0) ? length(var.azs) : 0

  description       = "${var.solution_name} static public ENI"
  subnet_id         = var.public_subnets[count.index]
  security_groups   = [aws_security_group.main.id]
  source_dest_check = false


  tags = {
    Name            = "${var.solution_name}-fck-network-intereface-${var.azs[count.index]}"
    Condition_check = "${var.solution_name}-fck-network-intereface"
  }
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

  depends_on = [aws_autoscaling_group.main] # Ensures ASG is created first
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

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    TERRAFORM_ENI_ID = aws_network_interface.public_subnets[count.index].id
    TERRAFORM_EIP_ID = aws_eip.main[count.index].id
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
    Name            = "${var.solution_name}-fck-nat-instance-${var.azs[count.index]}"
    Condition_check = "${var.solution_name}-fck-nat-instance"
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
  # Tag for condition check in iam
  tag {
    key                 = "Condition_check"
    value               = "${var.solution_name}-fck-nat-instance"
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

# resource "aws_iam_policy" "main" {
#   name   = var.solution_name
#   policy = data.aws_iam_policy_document.main.json
#   tags   = var.tags
# }
#
# resource "aws_iam_role_policy_attachment" "main" {
#   role       = aws_iam_role.main.name
#   policy_arn = aws_iam_policy.main.arn
# }

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.main.name
}

#tfsec:ignore:aws-iam-no-policy-wildcards # could be more restrictive
resource "aws_iam_role_policy" "create_main" {
  count       = length(var.azs)
  role        = aws_iam_role.main.name
  name_prefix = "${var.solution_name}-fck-nat-policy-${var.azs[count.index]}-"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Sid": "ManageNetworkInterface",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Name": "${var.solution_name}-fck-nat-instance-${var.azs[count.index]}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Sid": "ManageEIPAllocation",
            "Action": [
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress"
            ],
            "Resource": "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/${aws_eip.main[count.index].allocation_id}"
        },
        {
            "Effect": "Allow",
            "Sid": "ManageEIPNetworkInterface",
            "Action": [
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress"
            ],
            "Resource": "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/${aws_network_interface.public_subnets[count.index].id}"
        }
    ]
}
EOF
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
    # condition {
    #   test     = "StringEquals"
    #   variable = "ec2:ResourceTag/Condition_check"
    #   values   = ["${var.solution_name}-fck-nat-instance"]
    # }
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
      # condition {
      #   test     = "StringEquals"
      #   variable = "ec2:ResourceTag/Condition_check"
      #   values   = ["${var.solution_name}-fck-nat-instance"]
      # }
    }
  }
}
