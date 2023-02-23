# ---------------------------------------------------------------------------------------------------------------------
### Create NAT instance(s) (as alternative to NAT gateway)
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "nat" {
  name = "${var.solution_name} ITO NAT instance"
  # name_prefix = var.name
  vpc_id      = var.vpc_id
  description = "Security group for NAT instance ${var.solution_name}"
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr # required by NAT instance function
resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.nat.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  protocol          = "-1"
  description       = "For NAT instance allow all outbound traffic."
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr # required by NAT instance function
resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.nat.id
  type              = "ingress"
  cidr_blocks       = var.private_subnets_cidr_blocks
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  protocol          = "-1"
  description       = "For NAT instance allow all inbound traffic from private subnets."
}

# ---------------------------------------------------------------------------------------------------------------------
# AMI of the latest Amazon Linux 2
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# for every private subnet
# ---------------------------------------------------------------------------------------------------------------------
data "aws_route_tables" "this" {
  count = length(var.private_subnets)

  filter {
    name   = "association.subnet-id"
    values = [var.private_subnets[count.index]]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# for 1-2 AZs create a nat_instance cloudinit_config
# ---------------------------------------------------------------------------------------------------------------------
data "cloudinit_config" "nat_instance" {
  count         = length(var.public_subnets_cidr_blocks)
  gzip          = false
  base64_encode = true

  part {
    filename     = "main.cfg"
    content_type = "text/cloud-config"
    content = <<EOF
#cloud-config
timezone: Europe/Berlin
write_files:
  - path: /usr/local/bin/nat-config
    owner: root:root
    permissions: '0755'
    content: |
      ${indent(6, templatefile("${local.script_path}/nat-config.tmpl", {
    route_table_ids = data.aws_route_tables.this[count.index].ids
}))}
  - path: /etc/systemd/system/nat-config.service
    owner: root:root
    permissions: '0755'
    content: |
      ${indent(6, file("${local.template_path}/nat-config.service"))}
EOF
}

part {
  content_type = "text/x-shellscript"
  content      = file("${local.script_path}/nat_init.sh")
}
}

locals {
  base_path     = "/home/ubuntu/cloud-init"
  script_path   = "${path.module}/cloud-init/scripts"
  template_path = "${path.module}/cloud-init/templates"
}

resource "aws_launch_template" "nat_template" {

  # -------------------------------------------------------------------------------------------------------------------
  # Launch Configurations/Templates cannot be updated after creation with
  # the AWS API. In order to update a Launch Configuration, Terraform will
  # destroy the existing resource and create a replacement.
  # -------------------------------------------------------------------------------------------------------------------

  # count defines a loop along all AZ's
  count = length(var.azs)

  # We're only setting the name_prefix here,
  # Terraform will add a random string at the end to keep it unique.
  name_prefix = "nat-instance-template-${var.azs[count.index]}-"
  image_id    = data.aws_ami.this.id

  iam_instance_profile {
    arn = aws_iam_instance_profile.nat_instance.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = concat([aws_security_group.nat.id], var.extra_security_groups)
    delete_on_termination       = true
  }

  # for the time of free tier (end of May 2020), use t2.micro for the first AZ, for the rest use the one defined in main.tf
  instance_type = var.nat_instance_types[0]

  # Enforce IMDSv2 (Source: https://docs.bridgecrew.io/docs/bc_aws_general_31)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = data.cloudinit_config.nat_instance[count.index].rendered

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_size = "8"
      volume_type = "gp2"
    }
  }

  description = "Launch template for NAT instance ${var.solution_name}"
  tags = {
    Name = "${var.solution_name}-nat-instance"
  }

  lifecycle {
    # Required to redeploy without an outage.
    create_before_destroy = true
    # avoid triggering redeploy just because of new image being available
    ignore_changes = [image_id]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create NAT autoscaling group for every public subnet
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "this" {

  # count defines a loop along all AZ's
  count = length(var.azs)

  # -------------------------------------------------------------------------------------------------------------------
  # Force a redeployment when launch configuration changes.
  # This will reset the desired capacity if it was changed due to
  # autoscaling events.
  # -------------------------------------------------------------------------------------------------------------------
  name                = "${aws_launch_template.nat_template[count.index].name}-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [var.public_subnets[count.index]]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.nat_use_spot_instance ? 0 : 1
      on_demand_percentage_above_base_capacity = var.nat_use_spot_instance ? 0 : 100
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.nat_template[count.index].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.nat_instance_types
        content {
          instance_type = override.value
        }
      }
    }
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

resource "aws_iam_instance_profile" "nat_instance" {
  name_prefix = "${var.solution_name}-"
  role        = aws_iam_role.nat_instance.name
}

resource "aws_iam_role" "nat_instance" {
  name_prefix        = "${var.solution_name}-"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nat_instance.name
}

# ---------------------------------------------------------------------------------------------------------------------
# create for every private subnet
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-iam-no-policy-wildcards # could be more restrictive
resource "aws_iam_role_policy" "create_route" {
  count       = length(var.private_subnets_cidr_blocks)
  role        = aws_iam_role.nat_instance.name
  name_prefix = "${var.solution_name}-"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateRoute",
                "ec2:DeleteRoute"
            ],
            "Resource": "arn:aws:ec2:*:*:route-table/${var.private_route_table_ids[count.index]}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        }
    ]
}
EOF
}
