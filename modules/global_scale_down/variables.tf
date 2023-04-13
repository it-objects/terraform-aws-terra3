variable "enable_environment_hibernation_sleep_schedule" {
  type        = bool
  description = "Select true to enable sleep environment hibernation."
  default     = false
}

variable "solution_name" {
  type = string
}

variable "environment_hibernation_sleep_schedule" {
  type        = string
  description = "Enter schedule details of sleep schedule."
  default     = ""
}

variable "environment_hibernation_wakeup_schedule" {
  type        = string
  description = "Enter schedule details of wakeup schedule."
  default     = ""
}

variable "cluster_name" {
  description = ""
  type        = string
}

variable "ecs_service_names" {
  description = ""
  type        = list(string)
}

variable "ecs_desire_task_count" {
  description = ""
  type        = list(number)
}

variable "db_instance_name" {
  description = ""
  type        = string
}

variable "bastion_host_asg_name" {
  description = "scale-down_autoscaling_group"
  type        = list(string)
}

variable "bastion_host_asg_max_capacity" {
  description = ""
  type        = list(number)
}

variable "bastion_host_asg_min_capacity" {
  description = ""
  type        = list(number)
}

variable "bastion_host_asg_desired_capacity" {
  description = ""
  type        = list(number)
}

variable "nat_instances_asg_names" {
  description = "nat_instances_autoscaling_group"
  type        = list(string)
}

variable "nat_instances_asg_max_capacity" {
  description = ""
  type        = list(number)
}

variable "nat_instances_asg_min_capacity" {
  description = ""
  type        = list(number)
}

variable "nat_instances_asg_desired_capacity" {
  description = ""
  type        = list(number)
}

variable "ecs_ec2_instances_asg_name" {
  description = "ecs_ecs_instances_autoscaling_group"
  type        = list(string)
}

variable "ecs_ec2_instances_asg_max_capacity" {
  description = ""
  type        = list(number)
}

variable "ecs_ec2_instances_asg_min_capacity" {
  description = ""
  type        = list(number)
}

variable "ecs_ec2_instances_asg_desired_capacity" {
  description = ""
  type        = list(number)
}
