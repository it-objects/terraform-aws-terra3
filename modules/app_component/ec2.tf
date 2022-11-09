locals {
  #learn how to pass cluster name without passing it hard-coded
  user_data = <<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${data.aws_ecs_cluster.selected.cluster_name}-1
    ECS_LOGLEVEL=debug
    EOF
  EOT
}
# terra3-ecs-ec2-env-cluster
#data.aws_ecs_cluster.selected.arn
#data.aws_ssm_parameter.ecs_cluster_name.value

resource "aws_ecs_cluster_capacity_providers" "ecs_ec2_cap_provider" {
  count              = local.create_ecs_with_ec2 ? 1 : 0
  cluster_name       = data.aws_ecs_cluster.selected.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.ecs_ec2_capacity_provider[0].name]

  default_capacity_provider_strategy {
    base              = 20
    weight            = 60
    capacity_provider = aws_ecs_capacity_provider.ecs_ec2_capacity_provider[0].name
  }
}

resource "aws_ecs_capacity_provider" "ecs_ec2_capacity_provider" {
  count = local.create_ecs_with_ec2 ? 1 : 0
  name  = "ec2_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_ec2_asg[count.index].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 60
    }
  }
}

resource "aws_autoscaling_group" "ecs_ec2_asg" {
  count               = local.create_ecs_with_ec2 ? 1 : 0
  name                = "ecs_ec2_autoscaling"
  vpc_zone_identifier = data.aws_subnets.private_subnets.ids #aws_subnet.private_subnets.*.id
  launch_template {
    id = aws_launch_template.ecs_ec2_launch_template[count.index].id
  }

  protect_from_scale_in     = true
  desired_capacity          = 2
  min_size                  = 0
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}
resource "aws_launch_template" "ecs_ec2_launch_template" {
  count                  = local.create_ecs_with_ec2 ? 1 : 0
  name_prefix            = "ecs_ec2_container_instance"
  image_id               = data.aws_ami.amazon-linux.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [data.aws_security_group.ecs_default_sg.id] #[aws_security_group.auto_scaling_sg.id]
  user_data              = base64encode(local.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_ec2_role[0].name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  monitoring {
    enabled = true
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ecs_ec2_container_instance"
    }
  }
}
