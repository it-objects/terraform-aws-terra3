# Internal Service DNS Module

## Overview

The `internal_service_dns` module manages a Route53 private hosted zone for internal service discovery within a VPC. This zone is created once at the Terra3 module level and shared across all Docker workload instances (`ec2_docker_workload` modules).

## Problem Solved

Previously, each `ec2_docker_workload` instance independently created a Route53 private zone. When multiple workloads were deployed (e.g., postgres, redis, nginx), they all tried to create the same zone, resulting in `ConflictingDomainExists` errors. The zone had `prevent_destroy = true`, preventing cleanup and blocking redeployment.

This module solves that by:
1. Creating the zone once at the Terra3 base module level
2. Exporting zone details to SSM Parameter Store
3. Allowing all workload instances to discover and reuse the same zone
4. Ensuring zone persists across workload lifecycle changes

## Architecture

### Zone Management

- **Zone Name:** `internal.{solution_name}.local` (customizable)
- **Scope:** VPC-specific (private hosted zone)
- **Lifecycle:** Created with `prevent_destroy = true` to ensure persistence
- **Discovery:** Zone ID and name exported to SSM for reuse

### Service Discovery Pattern

```
postgres.internal.myapp.local    → 10.0.1.5
redis.internal.myapp.local       → 10.0.1.10
nginx.internal.myapp.local       → 10.0.1.15
```

Each workload creates its own DNS A record pointing to its instance IP, but all use the same shared zone.

### SSM Parameter Store Exports

- **Zone ID:** `/{solution_name}/internal_service_dns/zone_id`
- **Zone Name:** `/{solution_name}/internal_service_dns/zone_name`

These parameters are read by `ec2_docker_workload` modules for DNS record creation.

## Usage

### Basic Usage

```hcl
module "internal_service_dns" {
  source = "./modules/internal_service_dns"

  enable        = true
  vpc_id        = module.vpc.vpc_id
  solution_name = "myapp"
  tags          = local.common_tags
}
```

### Custom Zone Name

```hcl
module "internal_service_dns" {
  source = "./modules/internal_service_dns"

  enable        = true
  vpc_id        = module.vpc.vpc_id
  solution_name = "myapp"
  zone_name     = "services.myapp.local"  # Custom domain
  tags          = local.common_tags
}
```

### Disable Internal DNS

```hcl
module "internal_service_dns" {
  source = "./modules/internal_service_dns"

  enable        = false
  vpc_id        = module.vpc.vpc_id
  solution_name = "myapp"
}
```

## Integration with ec2_docker_workload

The `ec2_docker_workload` module automatically discovers the zone:

```hcl
module "postgres_docker" {
  source = "./modules/ec2_docker_workload"

  solution_name = "myapp"
  instance_name = "postgres"
  docker_image_uri = "postgres:15-alpine"

  port_mappings = [{
    containerPort = 5432
    hostPort      = 5432
    protocol      = "tcp"
  }]

  # Zone is auto-discovered from SSM
  # No zone configuration needed!
}
```

The workload module:
1. Reads zone ID and name from SSM parameters
2. Creates a DNS A record: `postgres.internal.myapp.local`
3. Points to the instance's private IP
4. Registers in the shared zone

## Deployment Sequence

### First Deployment

1. Terra3 base module creates Route53 zone via `internal_service_dns`
2. Zone ID and name stored in SSM
3. ec2_docker_workload modules deployed
4. Each reads zone from SSM and creates its DNS record
5. Services can resolve workload names

### Add New Workload

```bash
terraform apply  # Deploy new ec2_docker_workload
```

- New workload reads zone from SSM
- Creates its own DNS A record
- No zone conflicts (zone already exists)

### Remove Workload

```bash
terraform destroy -target=module.new_workload
```

- Workload's DNS A record removed
- Shared zone persists (`prevent_destroy = true`)
- Other workloads unaffected

### Restore from Zone Persistence

```bash
terraform import module.internal_service_dns[0].aws_route53_zone.internal <zone-id>
```

If zone data is lost but the AWS zone exists, import it back:

```bash
terraform import \
  'module.internal_service_dns[0].aws_route53_zone.internal' \
  'Z1234567890ABC'
```

## Existing Zone Import

To use an existing Route53 zone instead of creating a new one:

```hcl
# Store existing zone ID in SSM first
resource "aws_ssm_parameter" "existing_zone_id" {
  name  = "/{solution_name}/internal_service_dns/zone_id"
  type  = "String"
  value = "Z1234567890ABC"
}

resource "aws_ssm_parameter" "existing_zone_name" {
  name  = "/{solution_name}/internal_service_dns/zone_name"
  type  = "String"
  value = "internal.myapp.local"
}

# Then disable module creation
module "internal_service_dns" {
  source = "./modules/internal_service_dns"

  enable        = false  # Skip creation, zone pre-created
  vpc_id        = module.vpc.vpc_id
  solution_name = "myapp"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `zone_id` | Route53 private zone ID |
| `zone_name` | Route53 private zone name |
| `zone_arn` | Route53 private zone ARN |

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable` | bool | `true` | Enable zone creation |
| `vpc_id` | string | required | VPC where zone is deployed |
| `solution_name` | string | required | Solution name (max 16 chars) |
| `zone_name` | string | `""` | Custom zone name (default: `internal.{solution_name}.local`) |
| `tags` | map(string) | `{}` | Resource tags |

## Lifecycle Management

### Zone Persistence

The zone is created with `prevent_destroy = true` to ensure it persists across workload updates and deletions. This is intentional because:

- Multiple workloads share the same zone
- Zone is a VPC-level singleton
- Prevents accidental destruction

### Manual Destruction

If you need to destroy the zone, either:

1. **Remove prevent_destroy:** Temporarily disable the lifecycle rule
2. **AWS Console:** Manually delete via Route53 in AWS console
3. **Terraform:** Use `-target` to destroy only the zone resource

```bash
# Remove all DNS records first
terraform destroy -target='module.postgres.aws_route53_record.workload'
terraform destroy -target='module.redis.aws_route53_record.workload'

# Then remove prevent_destroy and destroy zone
terraform destroy -target='module.internal_service_dns'
```

## Troubleshooting

### Zone Not Found in SSM

**Error:** `Error reading SSM Parameter: ParameterNotFound`

**Solution:** Ensure `internal_service_dns` module is deployed with `enable = true`

```hcl
module "internal_service_dns" {
  source = "./modules/internal_service_dns"
  enable = true  # Must be true
  ...
}
```

### ConflictingDomainExists Error

**Error:** `ConflictingDomainExists` when deploying workload

**Solution:** Zone name differs between workloads. Ensure all use the same zone:

```hcl
# All workloads use same zone name
zone_name = "internal.myapp.local"
```

### Cannot Delete Zone (prevent_destroy)

**Error:** `Resource has lifecycle.prevent_destroy set, but the plan calls for this resource to be destroyed`

**Solution:** Explicitly allow destruction (if you really want to delete):

1. Remove from Terraform state (data persists in AWS)
2. Manually delete via AWS console
3. Remove `prevent_destroy` (use with caution)

## See Also

- **Terra3 Base Module:** Core infrastructure orchestration
- **EC2 Docker Workload Module:** Individual workload deployment
- **DNS and Certificates Module:** Route53 and ACM certificate management
- **VPC Module:** VPC and networking setup

## Related Patterns

### Multiple Workloads with Shared Zone

```hcl
# Shared zone created once
module "internal_service_dns" {
  source = "./modules/internal_service_dns"
  ...
}

# Multiple workloads auto-discover zone
module "postgres_docker" {
  source = "./modules/ec2_docker_workload"
  instance_name = "postgres"
  ...
}

module "redis_docker" {
  source = "./modules/ec2_docker_workload"
  instance_name = "redis"
  ...
}

module "nginx_docker" {
  source = "./modules/ec2_docker_workload"
  instance_name = "nginx"
  ...
}

# All three workloads register in the same zone
# ECS tasks access via: postgres.internal.myapp.local, etc.
```

### Zone with Custom Domain

```hcl
module "internal_service_dns" {
  source = "./modules/internal_service_dns"
  zone_name = "services.mycompany.local"
  ...
}

# Results in workload DNS names like:
# postgres.services.mycompany.local
# redis.services.mycompany.local
```

## Backwards Compatibility

For existing deployments with zones created by individual `ec2_docker_workload` modules:

1. **Import zone into base module:**
   ```bash
   terraform import 'module.internal_service_dns[0].aws_route53_zone.internal' 'Z1234567890ABC'
   ```

2. **Store zone ID in SSM:**
   ```bash
   aws ssm put-parameter --name "/{solution_name}/internal_service_dns/zone_id" \
     --type String --value "Z1234567890ABC"
   aws ssm put-parameter --name "/{solution_name}/internal_service_dns/zone_name" \
     --type String --value "internal.myapp.local"
   ```

3. **Remove zone from workload modules:**
   ```bash
   terraform state rm 'module.postgres_docker.aws_route53_zone.internal[0]'
   ```

4. **Update workload module configuration** to remove DNS zone variables
