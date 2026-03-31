# EBS Snapshot Lifecycle Module

Automatic EBS volume snapshotting for ECS Fargate tasks with persistent storage. Captures data on task stop and restores from the latest snapshot on next launch.

## How It Works

ECS Fargate managed EBS volumes are ephemeral -- they're created per task and destroyed when the task stops. This module bridges that gap by snapshotting volumes before destruction and restoring from snapshots on the next launch.

### Snapshot Lifecycle Flow

```
                          ECS Service (desiredCount=1)
                                    |
                    +---------------+---------------+
                    |                               |
               Normal Run                    Deployment / Stop
                    |                               |
        +-----------+-----------+                   |
        |  Task running in AZ   |          Task enters STOPPING
        |  with EBS volume      |                   |
        |  (from snapshot or    |                   v
        |   fresh if first run) |     +----------------------------+
        +-----------------------+     | EventBridge fires          |
                                      | "ECS Task State Change"    |
                                      | lastStatus = STOPPING      |
                                      +-------------+--------------+
                                                    |
                                                    v
                                      +----------------------------+
                                      | Lambda: Safety checks      |
                                      | - Correct service?         |
                                      | - Multiple deployments?    |
                                      |   (skip if yes)            |
                                      | - DynamoDB idempotency     |
                                      +-------------+--------------+
                                                    |
                                                    v
                                      +----------------------------+
                                      | Lambda: Pause service      |
                                      | desiredCount = 0           |
                                      | (prevents ECS from         |
                                      |  launching replacement     |
                                      |  with stale snapshot)      |
                                      +-------------+--------------+
                                                    |
                                                    v
                                      +----------------------------+
                                      | Lambda: Create snapshot    |
                                      | from EBS volume            |
                                      | (regional -- works in      |
                                      |  any AZ on restore)        |
                                      +-------------+--------------+
                                                    |
                                                    v
                                      +----------------------------+
                                      | Lambda: Wait for snapshot  |
                                      | completion (polls every    |
                                      | 10s, timeout 9min)         |
                                      +-------------+--------------+
                                                    |
                                        +-----------+-----------+
                                        |                       |
                                   Completed                 Failed
                                        |                       |
                                        v                       v
                              +------------------+   +---------------------+
                              | Store snapshot   |   | SSM = "failed"      |
                              | ID in SSM        |   | desiredCount = 0    |
                              +--------+---------+   | SNS alert sent      |
                                       |             | (manual recovery    |
                                       v             |  required)          |
                              +------------------+   +---------------------+
                              | UpdateService:   |
                              | - new snapshot   |
                              | - desiredCount=1 |
                              | (single deploy)  |
                              +--------+---------+
                                       |
                                       v
                              +------------------+
                              | Cleanup old      |
                              | snapshots        |
                              | (keep N recent,  |
                              |  protect in-use) |
                              +--------+---------+
                                       |
                                       v
                              +------------------+
                              | New task starts  |
                              | EBS volume       |
                              | created from     |
                              | latest snapshot  |
                              | (any AZ)         |
                              +------------------+
```

### Multi-AZ Behavior

EBS snapshots are regional. A snapshot taken from a volume in `eu-central-1a` restores into a new volume in `eu-central-1b` without any extra steps.

```
  Task stops in AZ-a          Snapshot (regional)         Task starts in AZ-b
  +----------------+         +------------------+         +----------------+
  | vol-abc (AZ-a) | ------> | snap-xyz         | ------> | vol-def (AZ-b) |
  | 5 GB data      |  create | (stored in S3,   | restore | 5 GB data      |
  +----------------+         |  not AZ-bound)   |         +----------------+
                              +------------------+
```

When `ebs_volume_availability_zone` is set, tasks are pinned to one AZ. When omitted, ECS places tasks in any AZ and the snapshot restores cross-AZ automatically.

### Deployment Timeline (Stop-Before-Start)

For stateful workloads, the service should use stop-before-start deployment to avoid a window where a new task runs with a stale snapshot while the old task still holds current data.

```
  Time ------>

  Old task:    [====== RUNNING ======][STOPPING]
  Lambda:                              [pause][snapshot...wait...][update service]
  New task:                                                        [== RUNNING ==]
                                       ^                           ^
                                       |                           |
                                  brief downtime             fresh snapshot
                                  (~30-60s typical)
```

## Components

| Resource | Purpose |
|----------|---------|
| Lambda function | Snapshots volume on task stop, updates ECS service |
| EventBridge rule | Triggers Lambda on `ECS Task State Change` (STOPPING) |
| DynamoDB table | Idempotency tracking (prevents concurrent processing) |
| SSM Parameter | Stores latest snapshot ID (`/{solution}/ebs_snapshot/{component}/latest_snapshot_id`) |
| CloudWatch alarm | Alerts on snapshot failures via SNS |
| SNS topic | Failure notifications (created if not provided) |

## Safety Features

- **Idempotency**: DynamoDB conditional writes prevent duplicate snapshot operations for the same volume/task
- **Loop prevention**: Skips events when multiple deployments are active (e.g., during `terraform apply`)
- **Service pause**: Sets `desiredCount=0` before snapshotting to prevent ECS from launching a replacement with a stale snapshot
- **Failure blocking**: On snapshot failure, sets SSM to `"failed"` and `desiredCount=0`. Terraform's precondition blocks further deploys until resolved
- **Snapshot protection**: Cleanup never deletes snapshots currently referenced by the ECS service
- **Retention**: Keeps the N most recent snapshots (default: 3), deletes older ones

## Usage

```hcl
module "terra3" {
  source = "../../"

  app_components = {
    postgres = {
      container = [module.postgres_container]
      ebs_volumes = [
        {
          name       = "postgres-data"
          size_in_gb = 10
        }
      ]
      enable_ebs_snapshot_lifecycle = true
      # ebs_volume_availability_zone = "eu-central-1a"  # Optional: pin to single AZ
    }
  }
}

module "ebs_snapshot_lifecycle" {
  source = "../../modules/ebs_snapshot_lifecycle"

  solution_name            = "myapp"
  app_component_name       = "postgres"
  cluster_arn              = data.aws_ecs_cluster.this.arn
  ecs_service_name         = "postgresService"
  volume_name              = "postgres-data"
  snapshot_retention_count = 3
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `solution_name` | string | (required) | Solution name for resource naming |
| `app_component_name` | string | (required) | App component whose EBS volumes to snapshot |
| `cluster_arn` | string | (required) | ECS cluster ARN |
| `ecs_service_name` | string | (required) | ECS service name (e.g., `postgresService`) |
| `volume_name` | string | (required) | EBS volume name in the task definition |
| `snapshot_retention_count` | number | `3` | Number of recent snapshots to keep |
| `file_system_type` | string | `"ext4"` | Filesystem type (must match task definition) |
| `alarm_sns_topic_arn` | string | `null` | Existing SNS topic for alerts. Creates one if null |
| `tags` | map(string) | `{}` | Tags for all resources |

## Failure Recovery

When a snapshot fails, the module blocks the service from restarting with stale data:

1. SSM parameter set to `"failed"`
2. Service `desiredCount` set to `0`
3. SNS alert sent with details
4. Terraform `precondition` blocks further deploys

To recover:

```bash
# Option A: Reset to use no snapshot (fresh volume)
aws ssm put-parameter \
  --name "/<solution>/ebs_snapshot/<component>/latest_snapshot_id" \
  --value "none" --type String --overwrite

# Option B: Set a known good snapshot
aws ssm put-parameter \
  --name "/<solution>/ebs_snapshot/<component>/latest_snapshot_id" \
  --value "snap-xxxxx" --type String --overwrite

# Then restore the service
aws ecs update-service --cluster <cluster> --service <service> --desired-count 1
```

## Constraints

- Requires `instances = 1` on the app component (Lambda assumes single task per service)
- Brief downtime during snapshot cycle (~30-60s depending on volume size)
- Snapshot timeout: 9 minutes. Volumes larger than ~100 GB may need the Lambda timeout increased
- Lambda memory: 128 MB (sufficient for API calls, no data processing)
