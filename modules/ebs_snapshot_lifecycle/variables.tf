# -----------------------------------------------
# EBS Snapshot Lifecycle - Variables
# -----------------------------------------------

variable "solution_name" {
  description = "Name of the solution (used for resource naming and tagging)"
  type        = string
}

variable "app_component_name" {
  description = "Name of the app component whose EBS volumes should be snapshotted"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "snapshot_retention_count" {
  description = "Number of most recent snapshots to keep per volume"
  type        = number
  default     = 3
}

variable "ecs_service_name" {
  description = "Name of the ECS service (as shown in the 'group' field of ECS events, e.g. 'postgresService')"
  type        = string
}

variable "volume_name" {
  description = "Name of the EBS volume in the ECS task definition"
  type        = string
}

variable "file_system_type" {
  description = "Filesystem type for the EBS volume (ext4, xfs). Must match the task definition."
  type        = string
  default     = "ext4"
}

variable "alarm_sns_topic_arn" {
  description = "ARN of an existing SNS topic for failure alerts. If not provided, a new topic is created."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
