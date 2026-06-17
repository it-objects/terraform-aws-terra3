# AMI Update Automation Module

Periodically checks for newer AMIs, updates the launch template, and triggers an ASG instance refresh to keep EC2 workloads patched automatically.

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AMI Update Automation Process                         │
└─────────────────────────────────────────────────────────────────────────┘

 ┌──────────────┐         ┌──────────────────┐
 │  EventBridge │ rate(7d)│   Lambda          │
 │  Schedule    │────────▶│   ami_updater.mjs │
 └──────────────┘         └────────┬─────────┘
                                   │
                    ┌──────────────┼──────────────────────────────┐
                    │              ▼                               │
                    │  ┌─────────────────────┐                    │
                    │  │ 1. DescribeImages    │                    │
                    │  │    (filter: al2023,  │                    │
                    │  │     arm64, gp3)      │                    │
                    │  └──────────┬──────────┘                    │
                    │             ▼                                │
                    │  ┌─────────────────────────────┐            │
                    │  │ 2. DescribeLaunchTemplate    │            │
                    │  │    Versions ($Latest)        │            │
                    │  └──────────┬──────────────────┘            │
                    │             ▼                                │
                    │  ┌─────────────────────┐                    │
                    │  │ 3. Compare AMI IDs  │                    │
                    │  └──────┬─────────┬────┘                    │
                    │         │         │                          │
                    │    Same │         │ Different                │
                    │         ▼         ▼                          │
                    │  ┌──────────┐  ┌──────────────────────┐     │
                    │  │ EXIT     │  │ 4. Check active       │     │
                    │  │ (no-op)  │  │    instance refresh   │     │
                    │  └──────────┘  └──────────┬───────────┘     │
                    │                           │                  │
                    │                  Active?  │  None?           │
                    │                    │      │                  │
                    │                    ▼      ▼                  │
                    │  ┌──────────┐  ┌──────────────────────────┐ │
                    │  │ EXIT     │  │ 5. CreateLaunchTemplate   │ │
                    │  │ (skip)   │  │    Version (new AMI)      │ │
                    │  └──────────┘  └──────────┬───────────────┘ │
                    │                           ▼                  │
                    │                ┌─────────────────────────┐   │
                    │                │ 6. StartInstanceRefresh  │   │
                    │                │    (Rolling, 0% healthy) │   │
                    │                └──────────┬──────────────┘   │
                    │                           ▼                  │
                    │                ┌─────────────────────────┐   │
                    │                │ 7. SNS Notification      │   │
                    │                │    (optional)            │   │
                    │                └─────────────────────────┘   │
                    │                                              │
                    └──────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     ASG Instance Refresh (AWS-managed)                   │
│                                                                         │
│  1. Terminate old instance (running stale AMI)                          │
│  2. Launch new instance from updated launch template (new AMI)          │
│  3. Wait for health check (instance_warmup: 300s)                       │
│  4. Mark refresh Successful (or rollback if unhealthy)                  │
└─────────────────────────────────────────────────────────────────────────┘
```

The Lambda only triggers the update. The actual instance replacement is handled by AWS Auto Scaling's native instance refresh mechanism, which includes automatic rollback if the new instance fails health checks.

## Usage

```hcl
module "bastion_ami_update" {
  source = "./modules/ami_update_automation"

  solution_name      = var.solution_name
  name_suffix        = "bastion"
  launch_template_id = module.bastion_host_ssm[0].launch_template_id
  asg_name           = module.bastion_host_ssm[0].bastion_host_autoscaling_group_name
}
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `solution_name` | - | Resource naming prefix |
| `name_suffix` | - | Unique suffix per instance (e.g., "bastion", "postgres") |
| `launch_template_id` | - | Target launch template ID |
| `asg_name` | - | Target Auto Scaling Group name |
| `ami_owners` | `["amazon"]` | AMI owner accounts |
| `ami_name_filter` | `"al2023-ami-2023*"` | AMI name pattern |
| `ami_architecture` | `"arm64"` | CPU architecture |
| `schedule_expression` | `"rate(7 days)"` | Check frequency |
| `min_healthy_percentage` | `0` | Min healthy % during refresh (0 for single-instance ASGs) |
| `instance_warmup_seconds` | `300` | Warmup period for new instance |
| `sns_topic_arn` | `""` | Optional SNS topic for notifications |

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No newer AMI | Lambda exits early, no action |
| Refresh already in progress | Lambda skips, next scheduled run retries |
| New instance unhealthy | ASG rolls back automatically |
| Lambda timeout mid-operation | Next run detects AMI mismatch, retries safely |

## Manual Invocation

```bash
aws lambda invoke --function-name <solution>-ami-update-<suffix> --region <region> /dev/stdout
```
