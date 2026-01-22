# EC2 Docker Workload Module

Deploy and manage persistent Docker-based workloads on EC2 instances with optional load balancer integration.

## Overview

This module deploys a single EC2 instance (via Auto Scaling Group) running a Docker container. It's designed for persistent workloads like databases or long-running services that need persistent storage.

**Key Features:**
- Runs Docker containers on cost-effective ARM-based EC2 instances (t4g family)
- Automatic EBS volume creation and mounting to Docker containers
- CloudWatch Logs integration for container output
- Optional ALB integration for external routing
- Internal access via security groups (ECS services)
- Automatic container restart on failure
- IMDSv2 security hardening
- SSM Session Manager access for debugging

## Usage

### Basic Example - Internal PostgreSQL Database

```hcl
module "postgres_docker" {
  source = "./modules/ec2_docker_workload"

  solution_name = "myapp"
  instance_name = "postgres"

  # Docker Configuration
  docker_image_uri = "postgres:15-alpine"

  # Port Mappings
  port_mappings = [
    {
      containerPort = 5432
      hostPort      = 5432
      protocol      = "tcp"
    }
  ]

  # Environment Variables
  environment_variables = {
    "POSTGRES_USER"     = "appuser"
    "POSTGRES_PASSWORD" = "SecurePassword123"
    "POSTGRES_DB"       = "appdb"
  }

  # EBS Volume for persistent data
  ebs_volumes = [
    {
      device_name           = "/dev/sdf"
      size                  = 50
      volume_type           = "gp3"
      mount_path            = "/var/lib/postgresql/data"
      delete_on_termination = false
    }
  ]

  # Network Configuration
  vpc_id           = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  tags = {
    Environment = "production"
    Component   = "Database"
  }
}
```

## Inputs

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `solution_name` | string | Solution name for resource naming (max 16 chars, lowercase alphanumeric + dashes) |
| `instance_name` | string | Workload name (e.g., "postgres", "redis", "api") |
| `docker_image_uri` | string | Docker image URI (e.g., "postgres:15", "123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest") |
| `port_mappings` | list(object) | Port mappings: `{containerPort, hostPort, protocol}` |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `security_group_ids` | list(string) | `[]` | Custom security groups. If empty, module creates default. |
| `environment_variables` | map(string) | `{}` | Environment variables passed to container |
| `ebs_volumes` | list(object) | `[]` | EBS volumes: `{device_name, size, volume_type, mount_path, delete_on_termination}` |
| `instance_type` | string | `"t4g.nano"` | EC2 instance type (ARM-based) |
| `root_volume_size` | number | `50` | Root volume size in GB |
| `root_volume_type` | string | `"gp3"` | Root volume type |
| `service_port` | number | `80` | Primary service port (for ALB) |
| `path_mapping` | string | `"/api/*"` | ALB path pattern for routing |
| `health_check_path` | string | `"/"` | ALB health check path |
| `enable_ecr_access` | bool | `false` | Allow ECR image pulling |
| `enable_s3_access` | bool | `false` | Allow S3 bucket access |
| `enable_secrets_manager` | bool | `false` | Allow Secrets Manager access |
| `log_retention_days` | number | `7` | CloudWatch log retention |
| `tags` | map(string) | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `asg_name` | Auto Scaling Group name |
| `asg_arn` | Auto Scaling Group ARN |
| `launch_template_id` | Launch template ID |
| `security_group_id` | Security group ID (if created by module) |
| `iam_role_arn` | IAM role ARN for EC2 instance |
| `log_group_name` | CloudWatch log group name |
| `log_group_arn` | CloudWatch log group ARN |
| `alb_target_group_arn` | ALB target group ARN (if ALB enabled) |
| `ssm_security_group_parameter` | SSM parameter path for security group ID |
| `ssm_log_group_parameter` | SSM parameter path for log group name |
| `docker_image_uri` | Docker image being run |

## Port Mappings

Port mappings define how container ports are exposed on the EC2 host:

```hcl
port_mappings = [
  {
    containerPort = 5432    # Port inside container
    hostPort      = 5432    # Port on EC2 host
    protocol      = "tcp"   # tcp or udp
  }
]
```

## EBS Volume Mounting

Mount persistent EBS volumes to Docker containers:

```hcl
ebs_volumes = [
  {    
    size                  = 50                              # Size in GB    
    mount_path            = "/var/lib/postgresql/data"     # Path in container    
  }
]
```

The module automatically:
1. Attaches the EBS volume to the EC2 instance
2. Formats and mounts it to `/mnt/{device_name}`
3. Mounts it into the Docker container at `mount_path`

## Environment Variables

Pass environment variables to the container:

```hcl
environment_variables = {
  "DATABASE_HOST"   = "postgres.example.com"
  "DATABASE_PORT"   = "5432"
  "LOG_LEVEL"       = "debug"
  "API_KEY"         = "secret-key-here"  # Consider using Secrets Manager
}
```

## Security

### IAM Permissions

The module creates an IAM role with:
- **Always enabled:** CloudWatch Logs access, SSM Session Manager
- **Optional:** ECR access, S3 access, Secrets Manager access

### Security Groups

- **Default:** Creates a security group allowing traffic from ALB or ECS tasks
- **Custom:** Provide your own security group IDs via `security_group_ids`

### Network Security

- Instances deployed in **private subnets only** (no public IPs)
- Access via AWS Systems Manager Session Manager (no SSH keys)
- IMDSv2 enforced (prevents SSRF attacks)

## Debugging

### Access EC2 Instance

Use AWS Systems Manager Session Manager:

```bash
aws ssm start-session --target <instance-id>
```

Then view Docker container logs:

```bash
docker ps                                   # List containers
docker logs <container-name>               # View logs
docker exec -it <container-name> bash      # Enter container
```

### CloudWatch Logs

View container logs in CloudWatch:

```
Log Group: /${solution_name}/ec2_docker_workload/${instance_name}
Log Stream: container-${instance_name}
```

### Update Stack

To update the Docker image or configuration:

1. Modify the Terraform variables
2. Run `terraform apply`
3. The ASG will perform a rolling update (creates new instance, terminates old one)

## Single Instance Recovery Mechanisms

Since this module deploys a single EC2 instance (not an ASG), here are recommended recovery and high-availability strategies:

### 1. **EBS Volume Snapshots** (Recommended for Data Recovery)
- Automated snapshots via AWS Backup or lifecycle policies
- Enable point-in-time recovery for persistent data
- Example: Daily snapshots retained for 30 days
```bash
aws ec2 create-snapshot --volume-id vol-xxx --description "postgres-daily-backup"
```

### 2. **CloudWatch Alarms + Auto-Recovery**
- Enable EC2 Auto-Recovery: if instance fails hardware checks, AWS automatically recovers it
- Set up alarms on Docker container exit or CloudWatch logs
- **Note**: Auto-Recovery works for hardware failures, not software failures

### 3. **Warm Standby Configuration** (For HA Requirements)
```hcl
# Option A: Keep a second instance in standby (requires manual failover)
module "postgres_docker_standby" {
  source = "./modules/ec2_docker_workload"
  # ... same configuration as primary
}

# Then manually promote standby in case of primary failure
```

### 4. **EBS Volume Optimization**
- Use `gp3` volumes (faster recovery than gp2)
- Enable EBS-optimized instance type
- Configure IOPS/throughput for consistent performance

### 5. **Application-Level Recovery**
- Implement retry logic in client applications
- Use connection pooling with timeout/retry
- For PostgreSQL: Enable connection failover in clients
```bash
# Example client connection string with timeout
PGCONNECT_TIMEOUT=10 \
PGREQUIRESSL=require \
psql -h postgres-primary ...
```

### 6. **Manual Replacement Workflow**
If instance fails beyond recovery:
```bash
# 1. Note the instance ID and security group
INSTANCE_ID=$(aws ssm get-parameter --name /solution/ec2_docker_workload/postgres/instance_id --query 'Parameter.Value')
VOLUMES=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].BlockDeviceMappings[*].Ebs.VolumeId')

# 2. Detach volumes from failed instance
aws ec2 detach-volume --volume-id vol-xxx

# 3. Update Terraform state to remove failed instance
terraform state rm module.postgres_docker.aws_instance.docker_workload

# 4. Re-apply to create new instance with same volumes
terraform apply

# 5. Attach previous volumes if using independent volumes
aws ec2 attach-volume --volume-id vol-xxx --instance-id i-yyy --device /dev/sdf
```

### 7. **CloudWatch Logs for Debugging**
- Always check logs before manually restarting
```bash
aws logs tail /ec2docker-psql/ec2_docker_workload/postgres --follow
```

### 8. **Data Backup Strategy**
- For persistent workloads, implement external backups
- PostgreSQL: Use `pg_dump` or WAL archiving
- Example cron job inside container:
```bash
0 2 * * * pg_dump dbname > /backup/dump-$(date +\%Y\%m\%d).sql
```

### Recommended Multi-Layer Approach
1. **Immediate Recovery** (< 1 min): EBS auto-recovery + Docker restart policies
2. **Short-term Recovery** (5-30 min): Snapshot-based volume recovery
3. **Long-term Recovery** (> 30 min): Manual instance recreation from snapshots
4. **High Availability** (if needed): Warm standby instance (manual failover)

## Limitations (Phase 1)

- Single instance only (no auto-scaling beyond 1)
- Bridge networking mode (not host or overlay)
- No custom health check scripts
- Limited to Amazon Linux 2023 (ARM or x86 AMI provided by AWS)
- No EFS support (EBS only)

## Future Enhancements

- Multi-instance auto-scaling with metrics-based scaling
- Custom health check configuration
- EFS support for shared storage
- Secrets Manager integration for environment variables
- Container restart policies and limits
- Custom Docker daemon parameters
- Scheduled scaling (scale down during off-hours)

## Examples

See `examples/ec2_docker_workload/` for complete examples:
- PostgreSQL database with persistent volume
- Integration with existing VPC and ECS services

## PostgreSQL-Specific Configuration

When deploying PostgreSQL or other databases with persistent data directories:

### Volume Mount Path Issue
PostgreSQL's `initdb` command fails if the data directory is not empty (e.g., contains `lost+found` from EBS formatting).

**Solution**: Use a subdirectory within the mount point:

```hcl
ebs_volumes = [
  {
    device_name           = "/dev/sdf"
    size                  = 50
    volume_type           = "gp3"
    mount_path            = "/var/lib/postgresql/data"  # Container path
    delete_on_termination = false
  }
]

# Then in Docker container, use:
environment_variables = {
  "PGDATA" = "/var/lib/postgresql/data/db"  # Subdirectory, not mount root
}
```

### Accessing from Bastion Host

To connect to PostgreSQL from the bastion host after deployment:

**Step 1**: Allow bastion security group access (already added automatically):
```bash
aws ec2 authorize-security-group-ingress \
  --group-id <postgres-sg> \
  --protocol tcp \
  --port 5432 \
  --cidr 172.72.0.131/32 \
  --region eu-central-1
```

**Step 2**: Connect from bastion host:
```bash
psql -h <postgres-private-ip> -p 5432 -U <username> -d <database>
```

**Or use Session Manager port forwarding**:
```bash
aws ssm start-session --target <postgres-instance-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters "localPortNumber=5432,portNumber=5432"

# Then connect locally: psql -h localhost -p 5432 -U appuser -d appdb
```

## Security Considerations

1. **Image Credentials:** Use ECR private repositories or managed secrets for sensitive images
2. **Environment Secrets:** Avoid storing secrets in `environment_variables`. Use Secrets Manager with `enable_secrets_manager = true`
3. **Volume Encryption:** EBS volumes are encrypted by default with AWS-managed keys
4. **Instance Access:** Only via AWS Systems Manager Session Manager (no SSH exposed)
5. **Container Isolation:** Containers run with limited permissions by default
6. **Database Access:** Bastion host has port 5432 ingress rule configured for PostgreSQL access

## Integration with Terra3

This module integrates with the existing Terra3 infrastructure:

1. **Security Groups:** Uses existing ECS task security groups for internal communication
2. **ALB:** Optionally registers with existing load balancer via SSM parameters
3. **VPC:** Deploys in private subnets of existing VPC
4. **SSM Parameters:** Stores configuration for cross-module discovery

Example integration with ECS app_components:

```hcl
# Services can discover Docker workload via security group
data "aws_security_group" "docker_workload_sg" {
  id = aws_ssm_parameter.docker_workload_sg_id.value
}

# Add ingress rule to Docker workload
resource "aws_security_group_rule" "ecs_to_docker" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = data.aws_security_group.docker_workload_sg.id
  source_security_group_id = module.security_groups.ecs_task_sg_id
}
```
