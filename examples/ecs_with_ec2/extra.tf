/*
Terraform will perform the following actions:

# module.terra3_examples.module.account[0].aws_ebs_encryption_by_default.enable_ebs_account_level_encryption[0] will be created
+ resource "aws_ebs_encryption_by_default" "enable_ebs_account_level_encryption" {
+ enabled = true
+ id      = (known after apply)
}

# module.terra3_examples.module.account[0].aws_s3_account_public_access_block.enable_s3_account_level_block[0] will be created
+ resource "aws_s3_account_public_access_block" "enable_s3_account_level_block" {
+ account_id              = (known after apply)
+ block_public_acls       = true
+ block_public_policy     = true
+ id                      = (known after apply)
+ ignore_public_acls      = true
+ restrict_public_buckets = true
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_ecs_cluster.selected will be read during apply
# (config refers to values not yet known)
<= data "aws_ecs_cluster" "selected" {
+ arn                                  = (known after apply)
+ cluster_name                         = (sensitive)
+ id                                   = (known after apply)
+ pending_tasks_count                  = (known after apply)
+ registered_container_instances_count = (known after apply)
+ running_tasks_count                  = (known after apply)
+ setting                              = (known after apply)
+ status                               = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_iam_policy_document.task_assume will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_iam_policy_document" "task_assume" {
+ id   = (known after apply)
+ json = (known after apply)

+ statement {
+ actions = [
+ "sts:AssumeRole",
]
+ effect  = "Allow"

+ principals {
+ identifiers = [
+ "ecs-tasks.amazonaws.com",
]
+ type        = "Service"
}
}
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_iam_policy_document.task_permissions will be read during apply
# (config refers to values not yet known)
<= data "aws_iam_policy_document" "task_permissions" {
+ id   = (known after apply)
+ json = (known after apply)

+ statement {
+ actions   = [
+ "logs:CreateLogStream",
+ "logs:PutLogEvents",
]
+ effect    = "Allow"
+ resources = [
+ (known after apply),
+ (known after apply),
]
}
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_region.current_region will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_region" "current_region" {
+ description = (known after apply)
+ endpoint    = (known after apply)
+ id          = (known after apply)
+ name        = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_security_group.ecs_default_sg will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_security_group" "ecs_default_sg" {
+ arn         = (known after apply)
+ description = (known after apply)
+ id          = (known after apply)
+ name        = "terra3-ecs-ec2-env_ecs_task_sg"
+ tags        = (known after apply)
+ vpc_id      = (known after apply)

+ timeouts {
+ read = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_security_group.mysql_marker_sg will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_security_group" "mysql_marker_sg" {
+ arn         = (known after apply)
+ description = (known after apply)
+ id          = (known after apply)
+ name        = "terra3-ecs-ec2-env_mysql_access_marker_sg"
+ tags        = (known after apply)
+ vpc_id      = (known after apply)

+ timeouts {
+ read = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_ssm_parameter.alb_arn will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_ssm_parameter" "alb_arn" {
+ arn     = (known after apply)
+ id      = (known after apply)
+ name    = "/terra3-ecs-ec2-env/alb_arn"
+ type    = (known after apply)
+ value   = (sensitive value)
+ version = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_ssm_parameter.ecs_cluster_name will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_ssm_parameter" "ecs_cluster_name" {
+ arn     = (known after apply)
+ id      = (known after apply)
+ name    = "/terra3-ecs-ec2-env/terra3-ecs-ec2-env-cluster/container_runtime_ecs_cluster_name"
+ type    = (known after apply)
+ value   = (sensitive value)
+ version = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_ssm_parameter.vpc_id will be read during apply
# (depends on a resource or a module with changes pending)
<= data "aws_ssm_parameter" "vpc_id" {
+ arn     = (known after apply)
+ id      = (known after apply)
+ name    = "/terra3-ecs-ec2-env/vpc_id"
+ type    = (known after apply)
+ value   = (sensitive value)
+ version = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_subnets.private_subnets will be read during apply
# (config refers to values not yet known)
<= data "aws_subnets" "private_subnets" {
+ id   = (known after apply)
+ ids  = (known after apply)
+ tags = {
+ "Tier" = "private"
}

+ filter {
# At least one attribute in this block is (or was) sensitive,
# so its contents will not be displayed.
}

+ timeouts {
+ read = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].data.aws_vpc.selected will be read during apply
# (config refers to values not yet known)
<= data "aws_vpc" "selected" {
+ arn                     = (known after apply)
+ cidr_block              = (known after apply)
+ cidr_block_associations = (known after apply)
+ default                 = (known after apply)
+ dhcp_options_id         = (known after apply)
+ enable_dns_hostnames    = (known after apply)
+ enable_dns_support      = (known after apply)
+ id                      = (sensitive)
+ instance_tenancy        = (known after apply)
+ ipv6_association_id     = (known after apply)
+ ipv6_cidr_block         = (known after apply)
+ main_route_table_id     = (known after apply)
+ owner_id                = (known after apply)
+ state                   = (known after apply)
+ tags                    = (known after apply)

+ timeouts {
+ read = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_appautoscaling_scheduled_action.WeekdayScaleDown[0] will be created
+ resource "aws_appautoscaling_scheduled_action" "WeekdayScaleDown" {
+ arn                = (known after apply)
+ id                 = (known after apply)
+ name               = "my_app_componentScaleDown"
+ resource_id        = "service/terra3-ecs-ec2-env-cluster/my_app_componentService"
+ scalable_dimension = "ecs:service:DesiredCount"
+ schedule           = "cron(0 17 ? * * *)"
+ service_namespace  = "ecs"
+ timezone           = "Europe/Berlin"

+ scalable_target_action {
+ max_capacity = "0"
+ min_capacity = "0"
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_appautoscaling_scheduled_action.WeekdayScaleUp[0] will be created
+ resource "aws_appautoscaling_scheduled_action" "WeekdayScaleUp" {
+ arn                = (known after apply)
+ id                 = (known after apply)
+ name               = "my_app_componentScaleUp"
+ resource_id        = "service/terra3-ecs-ec2-env-cluster/my_app_componentService"
+ scalable_dimension = "ecs:service:DesiredCount"
+ schedule           = "cron(0 8 ? * MON-FRI *)"
+ service_namespace  = "ecs"
+ timezone           = "Europe/Berlin"

+ scalable_target_action {
+ max_capacity = "1"
+ min_capacity = "1"
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_appautoscaling_target.ServiceAutoScalingTarget[0] will be created
+ resource "aws_appautoscaling_target" "ServiceAutoScalingTarget" {
+ id                 = (known after apply)
+ max_capacity       = 1
+ min_capacity       = 0
+ resource_id        = "service/terra3-ecs-ec2-env-cluster/my_app_componentService"
+ role_arn           = (known after apply)
+ scalable_dimension = "ecs:service:DesiredCount"
+ service_namespace  = "ecs"
}

# module.terra3_examples.module.app_components["my_app_component"].aws_cloudwatch_log_group.CloudWatchLogGroup will be created
+ resource "aws_cloudwatch_log_group" "CloudWatchLogGroup" {
+ arn               = (known after apply)
+ id                = (known after apply)
+ name              = "my_app_componentLogGroup"
+ retention_in_days = 7
+ tags              = {
+ "Name" = "my_app_componentLogGroup"
}
+ tags_all          = {
+ "Environment" = "qa"
+ "Name"        = "my_app_componentLogGroup"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_ecs_service.ecs_service will be created
+ resource "aws_ecs_service" "ecs_service" {
+ cluster                            = (known after apply)
+ deployment_maximum_percent         = 200
+ deployment_minimum_healthy_percent = 100
+ desired_count                      = 1
+ enable_ecs_managed_tags            = false
+ enable_execute_command             = false
+ health_check_grace_period_seconds  = 0
+ iam_role                           = (known after apply)
+ id                                 = (known after apply)
+ launch_type                        = "EC2"
+ name                               = "my_app_componentService"
+ platform_version                   = "LATEST"
+ scheduling_strategy                = "REPLICA"
+ tags_all                           = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ task_definition                    = (known after apply)
+ wait_for_steady_state              = false

+ load_balancer {
+ container_name   = "my_main_container"
+ container_port   = 80
+ target_group_arn = (known after apply)
}

+ network_configuration {
+ assign_public_ip = false
+ security_groups  = (known after apply)
+ subnets          = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_ecs_task_definition.ecs_task_definition will be created
+ resource "aws_ecs_task_definition" "ecs_task_definition" {
+ arn                      = (known after apply)
+ container_definitions    = (known after apply)
+ cpu                      = "256"
+ execution_role_arn       = (known after apply)
+ family                   = "my_app_component"
+ id                       = (known after apply)
+ memory                   = "512"
+ network_mode             = "awsvpc"
+ requires_compatibilities = [
+ "EC2",
]
+ revision                 = (known after apply)
+ skip_destroy             = false
+ tags                     = {
+ "Name" = "my_app_component-task-def"
}
+ tags_all                 = {
+ "Environment" = "qa"
+ "Name"        = "my_app_component-task-def"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ task_role_arn            = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].aws_iam_role.ExecutionRole will be created
+ resource "aws_iam_role" "ExecutionRole" {
+ arn                   = (known after apply)
+ assume_role_policy    = jsonencode(
{
+ Statement = [
+ {
+ Action    = "sts:AssumeRole"
+ Effect    = "Allow"
+ Principal = {
+ Service = "ecs-tasks.amazonaws.com"
}
+ Sid       = ""
},
]
+ Version   = "2012-10-17"
}
)
+ create_date           = (known after apply)
+ force_detach_policies = false
+ id                    = (known after apply)
+ managed_policy_arns   = (known after apply)
+ max_session_duration  = 3600
+ name                  = "my_app_component-ExecutionRole"
+ name_prefix           = (known after apply)
+ path                  = "/"
+ tags                  = {
+ "Name" = "my_app_componentExecutionRole"
}
+ tags_all              = {
+ "Environment" = "qa"
+ "Name"        = "my_app_componentExecutionRole"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ unique_id             = (known after apply)

+ inline_policy {
+ name   = (known after apply)
+ policy = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_iam_role.task will be created
+ resource "aws_iam_role" "task" {
+ arn                   = (known after apply)
+ assume_role_policy    = (known after apply)
+ create_date           = (known after apply)
+ force_detach_policies = false
+ id                    = (known after apply)
+ managed_policy_arns   = (known after apply)
+ max_session_duration  = 3600
+ name                  = "my_app_component-task-role"
+ name_prefix           = (known after apply)
+ path                  = "/"
+ tags_all              = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ unique_id             = (known after apply)

+ inline_policy {
+ name   = (known after apply)
+ policy = (known after apply)
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_iam_role_policy.log_agent will be created
+ resource "aws_iam_role_policy" "log_agent" {
+ id     = (known after apply)
+ name   = "log-permissions"
+ policy = (known after apply)
+ role   = (known after apply)
}

# module.terra3_examples.module.app_components["my_app_component"].aws_iam_role_policy_attachment.ExecutionRole_to_ecsTaskExecutionRole will be created
+ resource "aws_iam_role_policy_attachment" "ExecutionRole_to_ecsTaskExecutionRole" {
+ id         = (known after apply)
+ policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
+ role       = "my_app_component-ExecutionRole"
}

# module.terra3_examples.module.app_components["my_app_component"].aws_lb_listener.port_80 will be created
+ resource "aws_lb_listener" "port_80" {
+ arn               = (known after apply)
+ id                = (known after apply)
+ load_balancer_arn = (sensitive)
+ port              = 80
+ protocol          = "HTTP"
+ ssl_policy        = (known after apply)
+ tags_all          = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}

+ default_action {
+ order = (known after apply)
+ type  = "redirect"

+ redirect {
+ host        = "terra3.io"
+ path        = "/#{path}"
+ port        = "443"
+ protocol    = "HTTPS"
+ query       = "#{query}"
+ status_code = "HTTP_302"
}
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_lb_listener_rule.http_listener_rule will be created
+ resource "aws_lb_listener_rule" "http_listener_rule" {
+ arn          = (known after apply)
+ id           = (known after apply)
+ listener_arn = (known after apply)
+ priority     = 200
+ tags_all     = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}

+ action {
+ order            = (known after apply)
+ target_group_arn = (known after apply)
+ type             = "forward"
}

+ condition {

+ path_pattern {
+ values = [
+ "/api*/
/*",
]
}
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_lb_listener_rule.http_trailing_slash_redirect will be created
+ resource "aws_lb_listener_rule" "http_trailing_slash_redirect" {
+ arn          = (known after apply)
+ id           = (known after apply)
+ listener_arn = (known after apply)
+ priority     = 201
+ tags_all     = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}

+ action {
+ order = (known after apply)
+ type  = "redirect"

+ redirect {
+ host        = "#{host}"
+ path        = "/#{path}/"
+ port        = "443"
+ protocol    = "HTTPS"
+ query       = "#{query}"
+ status_code = "HTTP_301"
}
}

+ condition {

+ path_pattern {
+ values = [
+ "/api",
]
}
}
}

# module.terra3_examples.module.app_components["my_app_component"].aws_lb_target_group.target_group will be created
+ resource "aws_lb_target_group" "target_group" {
+ arn                                = (known after apply)
+ arn_suffix                         = (known after apply)
+ connection_termination             = false
+ deregistration_delay               = "10"
+ id                                 = (known after apply)
+ ip_address_type                    = (known after apply)
+ lambda_multi_value_headers_enabled = false
+ load_balancing_algorithm_type      = (known after apply)
+ name                               = (known after apply)
+ name_prefix                        = "my-app"
+ port                               = 80
+ preserve_client_ip                 = (known after apply)
+ protocol                           = "HTTP"
+ protocol_version                   = (known after apply)
+ proxy_protocol_v2                  = false
+ slow_start                         = 0
+ tags_all                           = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ target_type                        = "ip"
+ vpc_id                             = (sensitive)

+ health_check {
+ enabled             = true
+ healthy_threshold   = 3
+ interval            = 30
+ matcher             = "200"
+ path                = "/"
+ port                = "80"
+ protocol            = "HTTP"
+ timeout             = 3
+ unhealthy_threshold = 2
}

+ stickiness {
+ cookie_duration = (known after apply)
+ cookie_name     = (known after apply)
+ enabled         = (known after apply)
+ type            = (known after apply)
}
}

# module.terra3_examples.module.cluster.aws_ecs_cluster.fargate_cluster[0] will be created
+ resource "aws_ecs_cluster" "fargate_cluster" {
+ arn                = (known after apply)
+ capacity_providers = (known after apply)
+ id                 = (known after apply)
+ name               = "terra3-ecs-ec2-env-cluster"
+ tags_all           = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}

+ default_capacity_provider_strategy {
+ base              = (known after apply)
+ capacity_provider = (known after apply)
+ weight            = (known after apply)
}

+ setting {
+ name  = (known after apply)
+ value = (known after apply)
}
}

# module.terra3_examples.module.cluster.aws_ecs_cluster_capacity_providers.fargate_cap_provider[0] will be created
+ resource "aws_ecs_cluster_capacity_providers" "fargate_cap_provider" {
+ capacity_providers = [
+ "FARGATE",
]
+ cluster_name       = "terra3-ecs-ec2-env-cluster"
+ id                 = (known after apply)

+ default_capacity_provider_strategy {
+ base              = 1
+ capacity_provider = "FARGATE"
+ weight            = 100
}
}

# module.terra3_examples.module.cluster.aws_ssm_parameter.ecs_cluster_name[0] will be created
+ resource "aws_ssm_parameter" "ecs_cluster_name" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2-env/terra3-ecs-ec2-env-cluster/container_runtime_ecs_cluster_name"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.container_runtime.aws_ecs_cluster.hello_world[0] will be created
+ resource "aws_ecs_cluster" "hello_world" {
+ arn                = (known after apply)
+ capacity_providers = (known after apply)
+ id                 = (known after apply)
+ name               = "hello_world"
+ tags_all           = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}

+ configuration {
+ execute_command_configuration {
+ logging = "OVERRIDE"
}
}

+ default_capacity_provider_strategy {
+ base              = (known after apply)
+ capacity_provider = (known after apply)
+ weight            = (known after apply)
}

+ setting {
+ name  = (known after apply)
+ value = (known after apply)
}
}

# module.terra3_examples.module.environment.aws_ssm_parameter.environment_alb_arn[0] will be created
+ resource "aws_ssm_parameter" "environment_alb_arn" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2-env/alb_arn"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.aws_ssm_parameter.environment_alb_url[0] will be created
+ resource "aws_ssm_parameter" "environment_alb_url" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2-env/alb_url"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.aws_ssm_parameter.vpc_id will be created
+ resource "aws_ssm_parameter" "vpc_id" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2-env/vpc_id"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.data.aws_iam_policy_document.s3_static_website_policy_document will be read during apply
# (config refers to values not yet known)
<= data "aws_iam_policy_document" "s3_static_website_policy_document" {
+ id   = (known after apply)
+ json = (known after apply)

+ statement {
+ actions   = [
+ "s3:GetObject",
]
+ resources = [
+ (known after apply),
]

+ principals {
+ identifiers = [
+ (known after apply),
]
+ type        = "AWS"
}
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_cloudfront_distribution.general_distribution will be created
+ resource "aws_cloudfront_distribution" "general_distribution" {
+ arn                            = (known after apply)
+ caller_reference               = (known after apply)
+ comment                        = "General Cloudfront distribution."
+ default_root_object            = "index.html"
+ domain_name                    = (known after apply)
+ enabled                        = true
+ etag                           = (known after apply)
+ hosted_zone_id                 = (known after apply)
+ http_version                   = "http2and3"
+ id                             = (known after apply)
+ in_progress_validation_batches = (known after apply)
+ is_ipv6_enabled                = true
+ last_modified_time             = (known after apply)
+ price_class                    = "PriceClass_All"
+ retain_on_delete               = false
+ status                         = (known after apply)
+ tags_all                       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ trusted_key_groups             = (known after apply)
+ trusted_signers                = (known after apply)
+ wait_for_deployment            = false

+ custom_error_response {
+ error_code         = 404
+ response_code      = 200
+ response_page_path = "/index.html"
}

+ default_cache_behavior {
+ allowed_methods          = [
+ "GET",
+ "HEAD",
+ "OPTIONS",
]
+ cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
+ cached_methods           = [
+ "GET",
+ "HEAD",
+ "OPTIONS",
]
+ compress                 = true
+ default_ttl              = 0
+ max_ttl                  = 0
+ min_ttl                  = 0
+ origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
+ target_origin_id         = "s3_static_website"
+ trusted_key_groups       = (known after apply)
+ trusted_signers          = (known after apply)
+ viewer_protocol_policy   = "redirect-to-https"
}

+ logging_config {
+ bucket          = (known after apply)
+ include_cookies = false
+ prefix          = "cf-logs/"
}

+ ordered_cache_behavior {
+ allowed_methods            = (known after apply)
+ cache_policy_id            = (known after apply)
+ cached_methods             = (known after apply)
+ compress                   = (known after apply)
+ default_ttl                = (known after apply)
+ field_level_encryption_id  = (known after apply)
+ max_ttl                    = (known after apply)
+ min_ttl                    = (known after apply)
+ origin_request_policy_id   = (known after apply)
+ path_pattern               = (known after apply)
+ realtime_log_config_arn    = (known after apply)
+ response_headers_policy_id = (known after apply)
+ smooth_streaming           = (known after apply)
+ target_origin_id           = (known after apply)
+ trusted_key_groups         = (known after apply)
+ trusted_signers            = (known after apply)
+ viewer_protocol_policy     = (known after apply)

+ forwarded_values {
+ headers                 = (known after apply)
+ query_string            = (known after apply)
+ query_string_cache_keys = (known after apply)

+ cookies {
+ forward           = (known after apply)
+ whitelisted_names = (known after apply)
}
}

+ function_association {
+ event_type   = (known after apply)
+ function_arn = (known after apply)
}

+ lambda_function_association {
+ event_type   = (known after apply)
+ include_body = (known after apply)
+ lambda_arn   = (known after apply)
}
}

+ origin {
+ connection_attempts      = (known after apply)
+ connection_timeout       = (known after apply)
+ domain_name              = (known after apply)
+ origin_access_control_id = (known after apply)
+ origin_id                = (known after apply)
+ origin_path              = (known after apply)

+ custom_header {
+ name  = (known after apply)
+ value = (known after apply)
}

+ custom_origin_config {
+ http_port                = (known after apply)
+ https_port               = (known after apply)
+ origin_keepalive_timeout = (known after apply)
+ origin_protocol_policy   = (known after apply)
+ origin_read_timeout      = (known after apply)
+ origin_ssl_protocols     = (known after apply)
}

+ origin_shield {
+ enabled              = (known after apply)
+ origin_shield_region = (known after apply)
}

+ s3_origin_config {
+ origin_access_identity = (known after apply)
}
}

+ restrictions {
+ geo_restriction {
+ locations        = (known after apply)
+ restriction_type = "none"
}
}

+ viewer_certificate {
+ cloudfront_default_certificate = true
+ minimum_protocol_version       = "TLSv1"
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_cloudfront_function.cf_function_rewrite_default_index_request will be created
+ resource "aws_cloudfront_function" "cf_function_rewrite_default_index_request" {
+ arn             = (known after apply)
+ code            = <<-EOT
            function handler(event) {
                var request = event.request;
                var uri = request.uri;

                // Check whether the URI is missing a file name.
                if (uri.endsWith('/admin/')) {
                    request.uri += 'index.html';
                }

                return request;
            }
        EOT
+ comment         = "CloudFront Function to add index.html to subdirectories."
+ etag            = (known after apply)
+ id              = (known after apply)
+ live_stage_etag = (known after apply)
+ name            = "terra3-ecs-ec2-RewriteDefaultIndexRequest"
+ publish         = true
+ runtime         = "cloudfront-js-1.0"
+ status          = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_cloudfront_origin_access_identity.origin_access_identity will be created
+ resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
+ caller_reference                = (known after apply)
+ cloudfront_access_identity_path = (known after apply)
+ comment                         = "OAI for static website."
+ etag                            = (known after apply)
+ iam_arn                         = (known after apply)
+ id                              = (known after apply)
+ s3_canonical_user_id            = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket.cloudfront_logs will be created
+ resource "aws_s3_bucket" "cloudfront_logs" {
+ acceleration_status         = (known after apply)
+ acl                         = (known after apply)
+ arn                         = (known after apply)
+ bucket                      = (known after apply)
+ bucket_domain_name          = (known after apply)
+ bucket_regional_domain_name = (known after apply)
+ force_destroy               = true
+ hosted_zone_id              = (known after apply)
+ id                          = (known after apply)
+ object_lock_enabled         = (known after apply)
+ policy                      = (known after apply)
+ region                      = (known after apply)
+ request_payer               = (known after apply)
+ tags_all                    = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ website_domain              = (known after apply)
+ website_endpoint            = (known after apply)

+ cors_rule {
+ allowed_headers = (known after apply)
+ allowed_methods = (known after apply)
+ allowed_origins = (known after apply)
+ expose_headers  = (known after apply)
+ max_age_seconds = (known after apply)
}

+ grant {
+ id          = (known after apply)
+ permissions = (known after apply)
+ type        = (known after apply)
+ uri         = (known after apply)
}

+ lifecycle_rule {
+ abort_incomplete_multipart_upload_days = (known after apply)
+ enabled                                = (known after apply)
+ id                                     = (known after apply)
+ prefix                                 = (known after apply)
+ tags                                   = (known after apply)

+ expiration {
+ date                         = (known after apply)
+ days                         = (known after apply)
+ expired_object_delete_marker = (known after apply)
}

+ noncurrent_version_expiration {
+ days = (known after apply)
}

+ noncurrent_version_transition {
+ days          = (known after apply)
+ storage_class = (known after apply)
}

+ transition {
+ date          = (known after apply)
+ days          = (known after apply)
+ storage_class = (known after apply)
}
}

+ logging {
+ target_bucket = (known after apply)
+ target_prefix = (known after apply)
}

+ object_lock_configuration {
+ object_lock_enabled = (known after apply)

+ rule {
+ default_retention {
+ days  = (known after apply)
+ mode  = (known after apply)
+ years = (known after apply)
}
}
}

+ replication_configuration {
+ role = (known after apply)

+ rules {
+ delete_marker_replication_status = (known after apply)
+ id                               = (known after apply)
+ prefix                           = (known after apply)
+ priority                         = (known after apply)
+ status                           = (known after apply)

+ destination {
+ account_id         = (known after apply)
+ bucket             = (known after apply)
+ replica_kms_key_id = (known after apply)
+ storage_class      = (known after apply)

+ access_control_translation {
+ owner = (known after apply)
}

+ metrics {
+ minutes = (known after apply)
+ status  = (known after apply)
}

+ replication_time {
+ minutes = (known after apply)
+ status  = (known after apply)
}
}

+ filter {
+ prefix = (known after apply)
+ tags   = (known after apply)
}

+ source_selection_criteria {
+ sse_kms_encrypted_objects {
+ enabled = (known after apply)
}
}
}
}

+ server_side_encryption_configuration {
+ rule {
+ bucket_key_enabled = (known after apply)

+ apply_server_side_encryption_by_default {
+ kms_master_key_id = (known after apply)
+ sse_algorithm     = (known after apply)
}
}
}

+ versioning {
+ enabled    = (known after apply)
+ mfa_delete = (known after apply)
}

+ website {
+ error_document           = (known after apply)
+ index_document           = (known after apply)
+ redirect_all_requests_to = (known after apply)
+ routing_rules            = (known after apply)
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket.s3_static_website will be created
+ resource "aws_s3_bucket" "s3_static_website" {
+ acceleration_status         = (known after apply)
+ acl                         = (known after apply)
+ arn                         = (known after apply)
+ bucket                      = (known after apply)
+ bucket_domain_name          = (known after apply)
+ bucket_regional_domain_name = (known after apply)
+ force_destroy               = true
+ hosted_zone_id              = (known after apply)
+ id                          = (known after apply)
+ object_lock_enabled         = (known after apply)
+ policy                      = (known after apply)
+ region                      = (known after apply)
+ request_payer               = (known after apply)
+ tags_all                    = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ website_domain              = (known after apply)
+ website_endpoint            = (known after apply)

+ cors_rule {
+ allowed_headers = (known after apply)
+ allowed_methods = (known after apply)
+ allowed_origins = (known after apply)
+ expose_headers  = (known after apply)
+ max_age_seconds = (known after apply)
}

+ grant {
+ id          = (known after apply)
+ permissions = (known after apply)
+ type        = (known after apply)
+ uri         = (known after apply)
}

+ lifecycle_rule {
+ abort_incomplete_multipart_upload_days = (known after apply)
+ enabled                                = (known after apply)
+ id                                     = (known after apply)
+ prefix                                 = (known after apply)
+ tags                                   = (known after apply)

+ expiration {
+ date                         = (known after apply)
+ days                         = (known after apply)
+ expired_object_delete_marker = (known after apply)
}

+ noncurrent_version_expiration {
+ days = (known after apply)
}

+ noncurrent_version_transition {
+ days          = (known after apply)
+ storage_class = (known after apply)
}

+ transition {
+ date          = (known after apply)
+ days          = (known after apply)
+ storage_class = (known after apply)
}
}

+ logging {
+ target_bucket = (known after apply)
+ target_prefix = (known after apply)
}

+ object_lock_configuration {
+ object_lock_enabled = (known after apply)

+ rule {
+ default_retention {
+ days  = (known after apply)
+ mode  = (known after apply)
+ years = (known after apply)
}
}
}

+ replication_configuration {
+ role = (known after apply)

+ rules {
+ delete_marker_replication_status = (known after apply)
+ id                               = (known after apply)
+ prefix                           = (known after apply)
+ priority                         = (known after apply)
+ status                           = (known after apply)

+ destination {
+ account_id         = (known after apply)
+ bucket             = (known after apply)
+ replica_kms_key_id = (known after apply)
+ storage_class      = (known after apply)

+ access_control_translation {
+ owner = (known after apply)
}

+ metrics {
+ minutes = (known after apply)
+ status  = (known after apply)
}

+ replication_time {
+ minutes = (known after apply)
+ status  = (known after apply)
}
}

+ filter {
+ prefix = (known after apply)
+ tags   = (known after apply)
}

+ source_selection_criteria {
+ sse_kms_encrypted_objects {
+ enabled = (known after apply)
}
}
}
}

+ server_side_encryption_configuration {
+ rule {
+ bucket_key_enabled = (known after apply)

+ apply_server_side_encryption_by_default {
+ kms_master_key_id = (known after apply)
+ sse_algorithm     = (known after apply)
}
}
}

+ versioning {
+ enabled    = (known after apply)
+ mfa_delete = (known after apply)
}

+ website {
+ error_document           = (known after apply)
+ index_document           = (known after apply)
+ redirect_all_requests_to = (known after apply)
+ routing_rules            = (known after apply)
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_acl.s3_bucket_acl will be created
+ resource "aws_s3_bucket_acl" "s3_bucket_acl" {
+ bucket = (known after apply)
+ id     = (known after apply)

+ access_control_policy {
+ grant {
+ permission = "FULL_CONTROL"

+ grantee {
+ display_name = (known after apply)
+ id           = "c1880d7eef2bb47f82bc5607dbb556af4c0b41d116dbd9a803a3c75f90494217"
+ type         = "CanonicalUser"
}
}
+ grant {
+ permission = "FULL_CONTROL"

+ grantee {
+ display_name = (known after apply)
+ id           = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
+ type         = "CanonicalUser"
}
}

+ owner {
+ display_name = (known after apply)
+ id           = "c1880d7eef2bb47f82bc5607dbb556af4c0b41d116dbd9a803a3c75f90494217"
}
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_acl.s3_static_website_bucket_acl will be created
+ resource "aws_s3_bucket_acl" "s3_static_website_bucket_acl" {
+ acl    = "private"
+ bucket = (known after apply)
+ id     = (known after apply)

+ access_control_policy {
+ grant {
+ permission = (known after apply)

+ grantee {
+ display_name  = (known after apply)
+ email_address = (known after apply)
+ id            = (known after apply)
+ type          = (known after apply)
+ uri           = (known after apply)
}
}

+ owner {
+ display_name = (known after apply)
+ id           = (known after apply)
}
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_cors_configuration.example will be created
+ resource "aws_s3_bucket_cors_configuration" "example" {
+ bucket = (known after apply)
+ id     = (known after apply)

+ cors_rule {
+ allowed_headers = [
+ "*",
]
+ allowed_methods = [
+ "GET",
+ "HEAD",
]
+ allowed_origins = (known after apply)
+ expose_headers  = [
+ "ETag",
]
+ max_age_seconds = 3000
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_policy.s3_static_website_policy will be created
+ resource "aws_s3_bucket_policy" "s3_static_website_policy" {
+ bucket = (known after apply)
+ id     = (known after apply)
+ policy = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_public_access_block.block will be created
+ resource "aws_s3_bucket_public_access_block" "block" {
+ block_public_acls       = true
+ block_public_policy     = true
+ bucket                  = (known after apply)
+ id                      = (known after apply)
+ ignore_public_acls      = true
+ restrict_public_buckets = true
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_public_access_block.block_static_website_bucket will be created
+ resource "aws_s3_bucket_public_access_block" "block_static_website_bucket" {
+ block_public_acls       = true
+ block_public_policy     = true
+ bucket                  = (known after apply)
+ id                      = (known after apply)
+ ignore_public_acls      = true
+ restrict_public_buckets = true
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_server_side_encryption_configuration.s3_enc_config will be created
+ resource "aws_s3_bucket_server_side_encryption_configuration" "s3_enc_config" {
+ bucket = (known after apply)
+ id     = (known after apply)

+ rule {
+ apply_server_side_encryption_by_default {
+ sse_algorithm = "AES256"
}
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_bucket_server_side_encryption_configuration.s3_static_website_enc_config will be created
+ resource "aws_s3_bucket_server_side_encryption_configuration" "s3_static_website_enc_config" {
+ bucket = (known after apply)
+ id     = (known after apply)

+ rule {
+ apply_server_side_encryption_by_default {
+ sse_algorithm = "AES256"
}
}
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_s3_object.object[0] will be created
+ resource "aws_s3_object" "object" {
+ acl                    = "private"
+ bucket                 = (known after apply)
+ bucket_key_enabled     = (known after apply)
+ content                = "<h1>Hello world, Terra3!</h1>"
+ content_type           = "text/html"
+ etag                   = (known after apply)
+ force_destroy          = false
+ id                     = (known after apply)
+ key                    = "index.html"
+ kms_key_id             = (known after apply)
+ server_side_encryption = (known after apply)
+ storage_class          = (known after apply)
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ version_id             = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_ssm_parameter.s3_static_website_bucket will be created
+ resource "aws_ssm_parameter" "s3_static_website_bucket" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2/s3-static-website-bucket"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.aws_ssm_parameter.s3_static_website_bucket_arn will be created
+ resource "aws_ssm_parameter" "s3_static_website_bucket_arn" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2/s3-static-website-bucket-arn"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.random_string.random_s3_postfix will be created
+ resource "random_string" "random_s3_postfix" {
+ id          = (known after apply)
+ length      = 4
+ lower       = true
+ min_lower   = 4
+ min_numeric = 0
+ min_special = 0
+ min_upper   = 0
+ number      = true
+ numeric     = true
+ result      = (known after apply)
+ special     = false
+ upper       = true
}

# module.terra3_examples.module.environment.module.cloudfront_cdn.random_string.random_s3_static_website_postfix will be created
+ resource "random_string" "random_s3_static_website_postfix" {
+ id          = (known after apply)
+ length      = 4
+ lower       = true
+ min_lower   = 4
+ min_numeric = 0
+ min_special = 0
+ min_upper   = 0
+ number      = true
+ numeric     = true
+ result      = (known after apply)
+ special     = false
+ upper       = true
}

# module.terra3_examples.module.environment.module.l7_loadbalancer[0].aws_lb.this will be created
+ resource "aws_lb" "this" {
+ arn                        = (known after apply)
+ arn_suffix                 = (known after apply)
+ desync_mitigation_mode     = "defensive"
+ dns_name                   = (known after apply)
+ drop_invalid_header_fields = true
+ enable_deletion_protection = false
+ enable_http2               = true
+ enable_waf_fail_open       = false
+ id                         = (known after apply)
+ idle_timeout               = 60
+ internal                   = false
+ ip_address_type            = (known after apply)
+ load_balancer_type         = "application"
+ name                       = "terra3-ecs-ec2-alb"
+ preserve_host_header       = false
+ security_groups            = (known after apply)
+ subnets                    = (known after apply)
+ tags_all                   = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                     = (known after apply)
+ zone_id                    = (known after apply)

+ subnet_mapping {
+ allocation_id        = (known after apply)
+ ipv6_address         = (known after apply)
+ outpost_id           = (known after apply)
+ private_ipv4_address = (known after apply)
+ subnet_id            = (known after apply)
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].data.aws_route_tables.this[0] will be read during apply
# (config refers to values not yet known)
<= data "aws_route_tables" "this" {
+ id   = (known after apply)
+ ids  = (known after apply)
+ tags = (known after apply)

+ filter {
+ name   = "association.subnet-id"
+ values = [
+ (known after apply),
]
}

+ timeouts {
+ read = (known after apply)
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].data.aws_route_tables.this[1] will be read during apply
# (config refers to values not yet known)
<= data "aws_route_tables" "this" {
+ id   = (known after apply)
+ ids  = (known after apply)
+ tags = (known after apply)

+ filter {
+ name   = "association.subnet-id"
+ values = [
+ (known after apply),
]
}

+ timeouts {
+ read = (known after apply)
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].data.cloudinit_config.nat_instance[0] will be read during apply
# (config refers to values not yet known)
<= data "cloudinit_config" "nat_instance" {
+ base64_encode = true
+ gzip          = false
+ id            = (known after apply)
+ rendered      = (known after apply)

+ part {
+ content      = (known after apply)
+ content_type = "text/cloud-config"
+ filename     = "main.cfg"
}
+ part {
+ content      = <<-EOT
                #!/bin/bash
                set -e

                export AWS_DEFAULT_REGION="$(/opt/aws/bin/ec2-metadata -z | sed 's/placement: \(.*\).$/\1/')"
                INSTANCE_ID="$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"

                disable_source_dest_check() {
                  aws ec2 modify-instance-attribute --no-source-dest-check --instance-id "$INSTANCE_ID"
                }

                enable_nat_config_service() {
                  systemctl daemon-reload
                  systemctl enable nat-config
                  systemctl start nat-config
                }

                {
                  disable_source_dest_check
                  enable_nat_config_service
                }
            EOT
+ content_type = "text/x-shellscript"
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].data.cloudinit_config.nat_instance[1] will be read during apply
# (config refers to values not yet known)
<= data "cloudinit_config" "nat_instance" {
+ base64_encode = true
+ gzip          = false
+ id            = (known after apply)
+ rendered      = (known after apply)

+ part {
+ content      = (known after apply)
+ content_type = "text/cloud-config"
+ filename     = "main.cfg"
}
+ part {
+ content      = <<-EOT
                #!/bin/bash
                set -e

                export AWS_DEFAULT_REGION="$(/opt/aws/bin/ec2-metadata -z | sed 's/placement: \(.*\).$/\1/')"
                INSTANCE_ID="$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"

                disable_source_dest_check() {
                  aws ec2 modify-instance-attribute --no-source-dest-check --instance-id "$INSTANCE_ID"
                }

                enable_nat_config_service() {
                  systemctl daemon-reload
                  systemctl enable nat-config
                  systemctl start nat-config
                }

                {
                  disable_source_dest_check
                  enable_nat_config_service
                }
            EOT
+ content_type = "text/x-shellscript"
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_autoscaling_group.this[0] will be created
+ resource "aws_autoscaling_group" "this" {
+ arn                       = (known after apply)
+ availability_zones        = (known after apply)
+ default_cooldown          = (known after apply)
+ desired_capacity          = 1
+ force_delete              = false
+ force_delete_warm_pool    = false
+ health_check_grace_period = 300
+ health_check_type         = (known after apply)
+ id                        = (known after apply)
+ max_size                  = 1
+ metrics_granularity       = "1Minute"
+ min_size                  = 1
+ name                      = (known after apply)
+ name_prefix               = (known after apply)
+ protect_from_scale_in     = false
+ service_linked_role_arn   = (known after apply)
+ vpc_zone_identifier       = (known after apply)
+ wait_for_capacity_timeout = "10m"

+ mixed_instances_policy {
+ instances_distribution {
+ on_demand_allocation_strategy            = (known after apply)
+ on_demand_base_capacity                  = 1
+ on_demand_percentage_above_base_capacity = 100
+ spot_allocation_strategy                 = (known after apply)
+ spot_instance_pools                      = (known after apply)
}

+ launch_template {
+ launch_template_specification {
+ launch_template_id   = (known after apply)
+ launch_template_name = (known after apply)
+ version              = "$Latest"
}

+ override {
+ instance_type = "t4g.nano"
}
}
}

+ tag {
+ key                 = "Name"
+ propagate_at_launch = true
+ value               = "terra3-ecs-ec2-nat-instance-eu-central-1a"
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_autoscaling_group.this[1] will be created
+ resource "aws_autoscaling_group" "this" {
+ arn                       = (known after apply)
+ availability_zones        = (known after apply)
+ default_cooldown          = (known after apply)
+ desired_capacity          = 1
+ force_delete              = false
+ force_delete_warm_pool    = false
+ health_check_grace_period = 300
+ health_check_type         = (known after apply)
+ id                        = (known after apply)
+ max_size                  = 1
+ metrics_granularity       = "1Minute"
+ min_size                  = 1
+ name                      = (known after apply)
+ name_prefix               = (known after apply)
+ protect_from_scale_in     = false
+ service_linked_role_arn   = (known after apply)
+ vpc_zone_identifier       = (known after apply)
+ wait_for_capacity_timeout = "10m"

+ mixed_instances_policy {
+ instances_distribution {
+ on_demand_allocation_strategy            = (known after apply)
+ on_demand_base_capacity                  = 1
+ on_demand_percentage_above_base_capacity = 100
+ spot_allocation_strategy                 = (known after apply)
+ spot_instance_pools                      = (known after apply)
}

+ launch_template {
+ launch_template_specification {
+ launch_template_id   = (known after apply)
+ launch_template_name = (known after apply)
+ version              = "$Latest"
}

+ override {
+ instance_type = "t4g.nano"
}
}
}

+ tag {
+ key                 = "Name"
+ propagate_at_launch = true
+ value               = "terra3-ecs-ec2-nat-instance-eu-central-1b"
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_iam_instance_profile.nat_instance will be created
+ resource "aws_iam_instance_profile" "nat_instance" {
+ arn         = (known after apply)
+ create_date = (known after apply)
+ id          = (known after apply)
+ name        = (known after apply)
+ name_prefix = "terra3-ecs-ec2-"
+ path        = "/"
+ role        = (known after apply)
+ tags_all    = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ unique_id   = (known after apply)
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_iam_role.nat_instance will be created
+ resource "aws_iam_role" "nat_instance" {
+ arn                   = (known after apply)
+ assume_role_policy    = jsonencode(
{
+ Statement = [
+ {
+ Action    = "sts:AssumeRole"
+ Effect    = "Allow"
+ Principal = {
+ Service = "ec2.amazonaws.com"
}
},
]
+ Version   = "2012-10-17"
}
)
+ create_date           = (known after apply)
+ force_detach_policies = false
+ id                    = (known after apply)
+ managed_policy_arns   = (known after apply)
+ max_session_duration  = 3600
+ name                  = (known after apply)
+ name_prefix           = "terra3-ecs-ec2-"
+ path                  = "/"
+ tags_all              = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ unique_id             = (known after apply)

+ inline_policy {
+ name   = (known after apply)
+ policy = (known after apply)
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_iam_role_policy.create_route[0] will be created
+ resource "aws_iam_role_policy" "create_route" {
+ id          = (known after apply)
+ name        = (known after apply)
+ name_prefix = "terra3-ecs-ec2-"
+ policy      = (known after apply)
+ role        = (known after apply)
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_iam_role_policy.create_route[1] will be created
+ resource "aws_iam_role_policy" "create_route" {
+ id          = (known after apply)
+ name        = (known after apply)
+ name_prefix = "terra3-ecs-ec2-"
+ policy      = (known after apply)
+ role        = (known after apply)
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_iam_role_policy_attachment.ssm will be created
+ resource "aws_iam_role_policy_attachment" "ssm" {
+ id         = (known after apply)
+ policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
+ role       = (known after apply)
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_launch_template.nat_template[0] will be created
+ resource "aws_launch_template" "nat_template" {
+ arn             = (known after apply)
+ default_version = (known after apply)
+ description     = "Launch template for NAT instance terra3-ecs-ec2"
+ id              = (known after apply)
+ image_id        = "ami-05a956edbde738375"
+ instance_type   = "t4g.nano"
+ latest_version  = (known after apply)
+ name            = (known after apply)
+ name_prefix     = "nat-instance-template-eu-central-1a-"
+ tags            = {
+ "Name" = "terra3-ecs-ec2-nat-instance"
}
+ tags_all        = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-nat-instance"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ user_data       = (known after apply)

+ block_device_mappings {
+ device_name = "/dev/xvda"

+ ebs {
+ encrypted   = "true"
+ iops        = (known after apply)
+ throughput  = (known after apply)
+ volume_size = 8
+ volume_type = "gp2"
}
}

+ iam_instance_profile {
+ arn = (known after apply)
}

+ metadata_options {
+ http_endpoint               = "enabled"
+ http_protocol_ipv6          = "disabled"
+ http_put_response_hop_limit = (known after apply)
+ http_tokens                 = "required"
+ instance_metadata_tags      = "disabled"
}

+ network_interfaces {
+ associate_public_ip_address = "true"
+ delete_on_termination       = "true"
+ security_groups             = (known after apply)
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_launch_template.nat_template[1] will be created
+ resource "aws_launch_template" "nat_template" {
+ arn             = (known after apply)
+ default_version = (known after apply)
+ description     = "Launch template for NAT instance terra3-ecs-ec2"
+ id              = (known after apply)
+ image_id        = "ami-05a956edbde738375"
+ instance_type   = "t4g.nano"
+ latest_version  = (known after apply)
+ name            = (known after apply)
+ name_prefix     = "nat-instance-template-eu-central-1b-"
+ tags            = {
+ "Name" = "terra3-ecs-ec2-nat-instance"
}
+ tags_all        = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-nat-instance"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ user_data       = (known after apply)

+ block_device_mappings {
+ device_name = "/dev/xvda"

+ ebs {
+ encrypted   = "true"
+ iops        = (known after apply)
+ throughput  = (known after apply)
+ volume_size = 8
+ volume_type = "gp2"
}
}

+ iam_instance_profile {
+ arn = (known after apply)
}

+ metadata_options {
+ http_endpoint               = "enabled"
+ http_protocol_ipv6          = "disabled"
+ http_put_response_hop_limit = (known after apply)
+ http_tokens                 = "required"
+ instance_metadata_tags      = "disabled"
}

+ network_interfaces {
+ associate_public_ip_address = "true"
+ delete_on_termination       = "true"
+ security_groups             = (known after apply)
}
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_security_group.nat will be created
+ resource "aws_security_group" "nat" {
+ arn                    = (known after apply)
+ description            = "Security group for NAT instance terra3-ecs-ec2"
+ egress                 = (known after apply)
+ id                     = (known after apply)
+ ingress                = (known after apply)
+ name                   = "terra3-ecs-ec2 ITO NAT instance"
+ name_prefix            = (known after apply)
+ owner_id               = (known after apply)
+ revoke_rules_on_delete = false
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                 = (known after apply)
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_security_group_rule.egress will be created
+ resource "aws_security_group_rule" "egress" {
+ cidr_blocks              = [
+ "0.0.0.0/0",
]
+ description              = "For NAT instance allow all outbound traffic."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "egress"
}

# module.terra3_examples.module.environment.module.nat_instances[0].aws_security_group_rule.ingress will be created
+ resource "aws_security_group_rule" "ingress" {
+ cidr_blocks              = [
+ "172.72.0.0/20",
+ "172.72.16.0/20",
]
+ description              = "For NAT instance allow all inbound traffic from private subnets."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "ingress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group.bastion_host_ssm_sg will be created
+ resource "aws_security_group" "bastion_host_ssm_sg" {
+ arn                    = (known after apply)
+ description            = "Security group for EC2 instance serving the purpose of a bastion host."
+ egress                 = (known after apply)
+ id                     = (known after apply)
+ ingress                = (known after apply)
+ name                   = "terra3-ecs-ec2-env_bastion_host_ssm_sg"
+ name_prefix            = (known after apply)
+ owner_id               = (known after apply)
+ revoke_rules_on_delete = false
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                 = (known after apply)
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group.ecs_task_sg will be created
+ resource "aws_security_group" "ecs_task_sg" {
+ arn                    = (known after apply)
+ description            = "Security group for an ECS task."
+ egress                 = (known after apply)
+ id                     = (known after apply)
+ ingress                = (known after apply)
+ name                   = "terra3-ecs-ec2-env_ecs_task_sg"
+ name_prefix            = (known after apply)
+ owner_id               = (known after apply)
+ revoke_rules_on_delete = false
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                 = (known after apply)
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group.loadbalancer_sg will be created
+ resource "aws_security_group" "loadbalancer_sg" {
+ arn                    = (known after apply)
+ description            = "Security group for loadbalancer."
+ egress                 = (known after apply)
+ id                     = (known after apply)
+ ingress                = (known after apply)
+ name                   = "terra3-ecs-ec2-env-loadbalancer_sg"
+ name_prefix            = (known after apply)
+ owner_id               = (known after apply)
+ revoke_rules_on_delete = false
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                 = (known after apply)
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group.mysql_access_marker_sg will be created
+ resource "aws_security_group" "mysql_access_marker_sg" {
+ arn                    = (known after apply)
+ description            = "Security group for tagging ECS tasks to allow access to a database."
+ egress                 = (known after apply)
+ id                     = (known after apply)
+ ingress                = (known after apply)
+ name                   = "terra3-ecs-ec2-env_mysql_access_marker_sg"
+ name_prefix            = (known after apply)
+ owner_id               = (known after apply)
+ revoke_rules_on_delete = false
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                 = (known after apply)
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group.mysql_db_sg will be created
+ resource "aws_security_group" "mysql_db_sg" {
+ arn                    = (known after apply)
+ description            = "Security group for MySQL allowing access by tagged instances only."
+ egress                 = (known after apply)
+ id                     = (known after apply)
+ ingress                = (known after apply)
+ name                   = "terra3-ecs-ec2-env_mysql_db_sg"
+ name_prefix            = (known after apply)
+ owner_id               = (known after apply)
+ revoke_rules_on_delete = false
+ tags_all               = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id                 = (known after apply)
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.bastion_host_ssm_sg_rule will be created
+ resource "aws_security_group_rule" "bastion_host_ssm_sg_rule" {
+ cidr_blocks              = [
+ "0.0.0.0/0",
]
+ description              = "From bastion host users should be able to access everything."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "egress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.ecs_task_egress_all will be created
+ resource "aws_security_group_rule" "ecs_task_egress_all" {
+ cidr_blocks              = [
+ "0.0.0.0/0",
]
+ description              = "ECS tasks may send traffic to everywhere. This rule should be more restricted depending on the container requirements."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "egress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.ecs_task_ingress will be created
+ resource "aws_security_group_rule" "ecs_task_ingress" {
+ description              = "ECS tasks may receive traffic from ALB."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "ingress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.ecs_task_ingress_self will be created
+ resource "aws_security_group_rule" "ecs_task_ingress_self" {
+ description              = "ECS tasks may receive traffic from other ECS tasks."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = true
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "ingress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.loadbalancer_egress_all will be created
+ resource "aws_security_group_rule" "loadbalancer_egress_all" {
+ description              = "Allow ALB egress traffic to ECS tasks only."
+ from_port                = 0
+ id                       = (known after apply)
+ protocol                 = "-1"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 0
+ type                     = "egress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.loadbalancer_ingress_http[0] will be created
+ resource "aws_security_group_rule" "loadbalancer_ingress_http" {
+ description              = "Allow ingress traffic to ALB from Cloudfront only."
+ from_port                = 80
+ id                       = (known after apply)
+ prefix_list_ids          = [
+ "pl-a3a144ca",
]
+ protocol                 = "tcp"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 80
+ type                     = "ingress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.mysql_db_sg_rule will be created
+ resource "aws_security_group_rule" "mysql_db_sg_rule" {
+ description              = "Allow ingress from marked ECS services on default MySQL port."
+ from_port                = 3306
+ id                       = (known after apply)
+ protocol                 = "tcp"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 3306
+ type                     = "ingress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_security_group_rule.mysql_db_sg_rule2 will be created
+ resource "aws_security_group_rule" "mysql_db_sg_rule2" {
+ description              = "Allow ingress from bastion host on default MySQL port."
+ from_port                = 3306
+ id                       = (known after apply)
+ protocol                 = "tcp"
+ security_group_id        = (known after apply)
+ self                     = false
+ source_security_group_id = (known after apply)
+ to_port                  = 3306
+ type                     = "ingress"
}

# module.terra3_examples.module.environment.module.security_groups.aws_ssm_parameter.ecs_task_sg_arn_param will be created
+ resource "aws_ssm_parameter" "ecs_task_sg_arn_param" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2-env/sg/ecs_task_arn"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.module.security_groups.aws_ssm_parameter.mysql_access_marker_sg_arn_param will be created
+ resource "aws_ssm_parameter" "mysql_access_marker_sg_arn_param" {
+ arn            = (known after apply)
+ data_type      = (known after apply)
+ id             = (known after apply)
+ insecure_value = (known after apply)
+ key_id         = (known after apply)
+ name           = "/terra3-ecs-ec2-env/sg/mysql_access_marker_arn"
+ tags_all       = {
+ "Environment" = "qa"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ tier           = (known after apply)
+ type           = "String"
+ value          = (sensitive value)
+ version        = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_internet_gateway.this[0] will be created
+ resource "aws_internet_gateway" "this" {
+ arn      = (known after apply)
+ id       = (known after apply)
+ owner_id = (known after apply)
+ tags     = {
+ "Name" = "terra3-ecs-ec2-vpc"
}
+ tags_all = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id   = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route.public_internet_gateway[0] will be created
+ resource "aws_route" "public_internet_gateway" {
+ destination_cidr_block = "0.0.0.0/0"
+ gateway_id             = (known after apply)
+ id                     = (known after apply)
+ instance_id            = (known after apply)
+ instance_owner_id      = (known after apply)
+ network_interface_id   = (known after apply)
+ origin                 = (known after apply)
+ route_table_id         = (known after apply)
+ state                  = (known after apply)

+ timeouts {
+ create = "5m"
}
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table.private[0] will be created
+ resource "aws_route_table" "private" {
+ arn              = (known after apply)
+ id               = (known after apply)
+ owner_id         = (known after apply)
+ propagating_vgws = (known after apply)
+ route            = (known after apply)
+ tags             = {
+ "Name" = "terra3-ecs-ec2-vpc-private-eu-central-1a"
}
+ tags_all         = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-private-eu-central-1a"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id           = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table.private[1] will be created
+ resource "aws_route_table" "private" {
+ arn              = (known after apply)
+ id               = (known after apply)
+ owner_id         = (known after apply)
+ propagating_vgws = (known after apply)
+ route            = (known after apply)
+ tags             = {
+ "Name" = "terra3-ecs-ec2-vpc-private-eu-central-1b"
}
+ tags_all         = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-private-eu-central-1b"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id           = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table.public[0] will be created
+ resource "aws_route_table" "public" {
+ arn              = (known after apply)
+ id               = (known after apply)
+ owner_id         = (known after apply)
+ propagating_vgws = (known after apply)
+ route            = (known after apply)
+ tags             = {
+ "Name" = "terra3-ecs-ec2-vpc-public"
}
+ tags_all         = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-public"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_id           = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table_association.private[0] will be created
+ resource "aws_route_table_association" "private" {
+ id             = (known after apply)
+ route_table_id = (known after apply)
+ subnet_id      = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table_association.private[1] will be created
+ resource "aws_route_table_association" "private" {
+ id             = (known after apply)
+ route_table_id = (known after apply)
+ subnet_id      = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table_association.public[0] will be created
+ resource "aws_route_table_association" "public" {
+ id             = (known after apply)
+ route_table_id = (known after apply)
+ subnet_id      = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_route_table_association.public[1] will be created
+ resource "aws_route_table_association" "public" {
+ id             = (known after apply)
+ route_table_id = (known after apply)
+ subnet_id      = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_subnet.private[0] will be created
+ resource "aws_subnet" "private" {
+ arn                                            = (known after apply)
+ assign_ipv6_address_on_creation                = false
+ availability_zone                              = "eu-central-1a"
+ availability_zone_id                           = (known after apply)
+ cidr_block                                     = "172.72.0.0/20"
+ enable_dns64                                   = false
+ enable_resource_name_dns_a_record_on_launch    = false
+ enable_resource_name_dns_aaaa_record_on_launch = false
+ id                                             = (known after apply)
+ ipv6_cidr_block_association_id                 = (known after apply)
+ ipv6_native                                    = false
+ map_public_ip_on_launch                        = false
+ owner_id                                       = (known after apply)
+ private_dns_hostname_type_on_launch            = (known after apply)
+ tags                                           = {
+ "Name" = "terra3-ecs-ec2-vpc-private-eu-central-1a"
+ "Tier" = "private"
}
+ tags_all                                       = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-private-eu-central-1a"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
+ "Tier"        = "private"
}
+ vpc_id                                         = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_subnet.private[1] will be created
+ resource "aws_subnet" "private" {
+ arn                                            = (known after apply)
+ assign_ipv6_address_on_creation                = false
+ availability_zone                              = "eu-central-1b"
+ availability_zone_id                           = (known after apply)
+ cidr_block                                     = "172.72.16.0/20"
+ enable_dns64                                   = false
+ enable_resource_name_dns_a_record_on_launch    = false
+ enable_resource_name_dns_aaaa_record_on_launch = false
+ id                                             = (known after apply)
+ ipv6_cidr_block_association_id                 = (known after apply)
+ ipv6_native                                    = false
+ map_public_ip_on_launch                        = false
+ owner_id                                       = (known after apply)
+ private_dns_hostname_type_on_launch            = (known after apply)
+ tags                                           = {
+ "Name" = "terra3-ecs-ec2-vpc-private-eu-central-1b"
+ "Tier" = "private"
}
+ tags_all                                       = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-private-eu-central-1b"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
+ "Tier"        = "private"
}
+ vpc_id                                         = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_subnet.public[0] will be created
+ resource "aws_subnet" "public" {
+ arn                                            = (known after apply)
+ assign_ipv6_address_on_creation                = false
+ availability_zone                              = "eu-central-1a"
+ availability_zone_id                           = (known after apply)
+ cidr_block                                     = "172.72.32.0/20"
+ enable_dns64                                   = false
+ enable_resource_name_dns_a_record_on_launch    = false
+ enable_resource_name_dns_aaaa_record_on_launch = false
+ id                                             = (known after apply)
+ ipv6_cidr_block_association_id                 = (known after apply)
+ ipv6_native                                    = false
+ map_public_ip_on_launch                        = true
+ owner_id                                       = (known after apply)
+ private_dns_hostname_type_on_launch            = (known after apply)
+ tags                                           = {
+ "Name" = "terra3-ecs-ec2-vpc-public-eu-central-1a"
+ "Tier" = "public"
}
+ tags_all                                       = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-public-eu-central-1a"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
+ "Tier"        = "public"
}
+ vpc_id                                         = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_subnet.public[1] will be created
+ resource "aws_subnet" "public" {
+ arn                                            = (known after apply)
+ assign_ipv6_address_on_creation                = false
+ availability_zone                              = "eu-central-1b"
+ availability_zone_id                           = (known after apply)
+ cidr_block                                     = "172.72.48.0/20"
+ enable_dns64                                   = false
+ enable_resource_name_dns_a_record_on_launch    = false
+ enable_resource_name_dns_aaaa_record_on_launch = false
+ id                                             = (known after apply)
+ ipv6_cidr_block_association_id                 = (known after apply)
+ ipv6_native                                    = false
+ map_public_ip_on_launch                        = true
+ owner_id                                       = (known after apply)
+ private_dns_hostname_type_on_launch            = (known after apply)
+ tags                                           = {
+ "Name" = "terra3-ecs-ec2-vpc-public-eu-central-1b"
+ "Tier" = "public"
}
+ tags_all                                       = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc-public-eu-central-1b"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
+ "Tier"        = "public"
}
+ vpc_id                                         = (known after apply)
}

# module.terra3_examples.module.environment.module.vpc.aws_vpc.this[0] will be created
+ resource "aws_vpc" "this" {
+ arn                                  = (known after apply)
+ cidr_block                           = "172.72.0.0/16"
+ default_network_acl_id               = (known after apply)
+ default_route_table_id               = (known after apply)
+ default_security_group_id            = (known after apply)
+ dhcp_options_id                      = (known after apply)
+ enable_classiclink                   = (known after apply)
+ enable_classiclink_dns_support       = (known after apply)
+ enable_dns_hostnames                 = true
+ enable_dns_support                   = true
+ id                                   = (known after apply)
+ instance_tenancy                     = "default"
+ ipv6_association_id                  = (known after apply)
+ ipv6_cidr_block                      = (known after apply)
+ ipv6_cidr_block_network_border_group = (known after apply)
+ main_route_table_id                  = (known after apply)
+ owner_id                             = (known after apply)
+ tags                                 = {
+ "Name" = "terra3-ecs-ec2-vpc"
}
+ tags_all                             = {
+ "Environment" = "qa"
+ "Name"        = "terra3-ecs-ec2-vpc"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
}

# module.terra3_examples.module.environment.module.vpc_endpoints.aws_vpc_endpoint.this["s3"] will be created
+ resource "aws_vpc_endpoint" "this" {
+ arn                   = (known after apply)
+ cidr_blocks           = (known after apply)
+ dns_entry             = (known after apply)
+ id                    = (known after apply)
+ ip_address_type       = (known after apply)
+ network_interface_ids = (known after apply)
+ owner_id              = (known after apply)
+ policy                = (known after apply)
+ prefix_list_id        = (known after apply)
+ private_dns_enabled   = false
+ requester_managed     = (known after apply)
+ route_table_ids       = (known after apply)
+ security_group_ids    = (known after apply)
+ service_name          = "com.amazonaws.eu-central-1.s3"
+ state                 = (known after apply)
+ subnet_ids            = (known after apply)
+ tags                  = {
+ "Name" = "s3-vpc-endpoint"
}
+ tags_all              = {
+ "Environment" = "qa"
+ "Name"        = "s3-vpc-endpoint"
+ "Project"     = "terra3"
+ "Terraform"   = "true"
}
+ vpc_endpoint_type     = "Gateway"
+ vpc_id                = (known after apply)

+ dns_options {
+ dns_record_ip_type = (known after apply)
}

+ timeouts {
+ create = "10m"
+ delete = "10m"
+ update = "10m"
}
}

Plan: 84 to add, 0 to change, 0 to destroy.

*/
