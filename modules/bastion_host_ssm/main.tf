# ---------------------------------------------------------------------------------------------------------------------
# EC2 Launch Template used by Autoscaling Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_launch_template" "my_asg_launch_template" {
  name_prefix   = "${var.solution_name}_"
  image_id      = "ami-06e14f82ec5afe2af" # updated Oct 31st 2023
  instance_type = "t4g.nano"
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.ssm_managed_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [data.aws_security_group.bastion_host_ssm_sg.id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted   = true
      volume_size = "8"
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      LaunchTemplate = "${var.solution_name}_launch_template"
      Name           = "${var.solution_name}-bastion-host-ssm"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Autoscaling Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "my_autoscaling_group" {
  name             = "${var.solution_name}_autoscaling_group"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.my_asg_launch_template.id
    version = "$Latest"
  }

  health_check_grace_period = 10 # for demo purposes quite low value
  default_cooldown          = 10 # for demo purposes quite low value

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Instance Profile and Role giving EC2 instance access to AWS SSM service
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ssm_managed_instance_profile" {
  name = "${var.solution_name}_ssm_managed_instance_profile"
  role = aws_iam_role.ssm_managed_instance_role.name
}

resource "aws_iam_role" "ssm_managed_instance_role" {
  name = "${var.solution_name}_ssm_managed_instance_role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : {
        "Effect" : "Allow",
        "Principal" : { "Service" : "ec2.amazonaws.com" },
        "Action" : "sts:AssumeRole"
      }
    }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_role_attach" {
  role       = aws_iam_role.ssm_managed_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
