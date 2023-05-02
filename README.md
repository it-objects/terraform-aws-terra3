# Terra3

[![pre-commit](https://github.com/it-objects/terraform-aws-terra3/actions/workflows/pre-commit.yaml/badge.svg)](https://github.com/it-objects/terraform-aws-terra3/actions/workflows/pre-commit.yaml)

Welcome to Terra3 - An opinionated Terraform module for quickly ramping-up 3-tier-architecture solutions in AWS!

This repository contains a collection of Terraform modules that aim to make it easier and faster for customers to get started with a 3-tier-architecture in AWS. It can be used to configure and manage parts of or the complete stack consisting of
* a static website served from S3 via Cloudfront
* and containerized backend/API run on ECS
* and an RDS MySQL database
that is fully bootstrapped and batteries included with best practices in mind.

## Getting Started

The easiest way to get started with Terra3 is to follow our [Getting Started guide](https://terra3.io/getting-started.html).

## Documentation

For complete project documentation, please visit our [documentation site](https://terra3.io/).

## Examples

To view examples for how you can leverage Terra3, please see the [examples](https://github.com/it-objects/terraform-aws-terra3/tree/main/examples) directory.

## Usage

The below demonstrates how you can leverage Terra3 to deploy a 3-tier-architecture, including a static website served via S3 and Cloudfront, a container (in this case an nginx for demo purposes). After a "terraform apply" a Cloudfront URL is shown, which after about 4 minutes should redirect to the static website on root ("/") and the nginx container on ("/api/").

```hcl
module "terra3_environment" {
  source  = "it-objects/terra3/aws"

  solution_name = "example_solution"

  create_load_balancer = true
  nat                  = "NAT_INSTANCES" # spawns EC2 instances instead of NAT Gateways for cost savings

  app_components = {
    backend_service = {
      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.api_container
      ]

      listener_rule_prio = 200
      path_mapping       = "/api/*"
      service_port       = 80
    }
  }
}

module "api_container" {
  source = "it-objects/terra3/aws//modules/container"

  name = "backend_service"

  container_image  = "nginxdemos/hello"
  container_cpu    = 256
  container_memory = 512

  port_mappings = [{ # container reachable by load balancer must share the same app_component's name and port
    protocol      = "tcp"
    containerPort = 80
  }]
}

# Please wait 1 minute until the Cloudfront distribution becomes available
output "static_website_url" {
  value       = "https://${module.terra3_environment.cloudfront_domain_name}/"
}
output "container_url" {
  value       = "https://${module.terra3_environment.cloudfront_domain_name}/api/"
}
```

## About

This project is maintained and published with :heart: by [it-objects GmbH](https://it-objects.de/cloud/).

We're a full-service software development company based in Essen, Germany & Lisbon, Portugal.

[Apply for a job](https://www.it-objects.de/jobs/), or hire us to help with your software development, and all things cloud and devops.
