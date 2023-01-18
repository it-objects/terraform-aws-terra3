variable "container_runtime_name" {
  description = ""
  type        = string
}

variable "solution_kms_key_id" {
  description = "Required for ECS exec. Either the key given by its id here is used or a new one is created."
  type        = string
  default     = ""
}

variable "enable_ecs_exec" {
  description = "Required for ECS exec. Either the key given by its id here is used or a new one is created."
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enables/disables more detailed logging via container insights for ECS."
  type        = bool
  default     = false
}

variable "solution_name" {
  type = string
}

variable "cluster_type" {
  description = "Select FARGATE for cluster type as FARGATE, or Select FARGATE_SPOT for cluster type as FARGATE_SPOT or select EC2 for cluster type as EC2."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "EC2"], var.cluster_type)
    error_message = "Only 'FARGATE', 'FARGATE_SPOT' and 'EC2' are allowed."
  }
}

variable "cluster_ec2_min_nodes" {
  description = "Select the minimum nodes of the EC2 instances."
  type        = number
}

variable "cluster_ec2_max_nodes" {
  description = "Select the maximum nodes of the EC2 instances."
  type        = number
}

variable "cluster_ec2_instance_type" {
  description = "Select instance type of the EC2 instances."
  type        = string
}

variable "cluster_ec2_desired_capacity" {
  description = "Select desired capacity of the EC2 instances."
  type        = number
}

variable "cluster_ec2_detailed_monitoring" {
  description = "Select the detailed monitoring of the EC2 instances."
  type        = bool
}

variable "cluster_ec2_volume_size" {
  description = "Select the ebs volume size of the EC2 instances."
  type        = number
}

variable "public_subnets" {
  type = list(any)
}

variable "vpc_security_group_ids" {
  default     = []
  type        = list(string)
  description = "List of security group ids."
}
