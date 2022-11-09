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

variable "environment_name" {
  type = string
}

variable "cluster_type" {
  description = "Select ECS_FARGATE for cluster type as FARGATE, or select ECS_EC2 for cluster type as EC2."
  type        = string
  default     = "ECS_FARGATE"

  validation {
    condition     = contains(["ECS_FARGATE", "ECS_EC2"], var.cluster_type)
    error_message = "Only 'ECS_FARGATE', and 'ECS_EC2' are allowed."
  }
}

variable "az_count" {
  default     = "2"
  description = "number of availability zones in above region"
}

variable "cpu" {
  default     = "512"
  description = "Container instacne CPU units to provision"
}

variable "memory" {
  default     = "512"
  description = "Container instance memory to provision (in MiB) not MB"
}

variable "architecture_image" {
  default     = "nginxdemos/hello"
  description = "docker image to run in this ECS cluster"
}


variable "fargate_cpu" {
  default     = "1024"
  description = "fargate instacne CPU units to provision,my requirent 1 vcpu so gave 1024"
}

variable "fargate_memory" {
  default     = "2048"
  description = "Fargate instance memory to provision (in MiB) not MB"
}

variable "app_port" {
  default     = "80"
  description = "portexposed on the docker image"
}

variable "health_check_path" {
  default = "/"
}

variable "aws_region" {
  default     = "eu-central-1"
  description = "aws region where our resources going to create choose"
  #replace the region as suits for your requirement
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "hello_image" {
  default     = "nginxdemos/hello"
  description = "docker image to run in this ECS cluster"
}
