# Terra3

[![pre-commit](https://github.com/it-objects/terraform-aws-terra3/actions/workflows/pre-commit.yaml/badge.svg)](https://github.com/it-objects/terraform-aws-terra3/actions/workflows/pre-commit.yaml)

Welcome to Terra3 - An opinionated Terraform module for quickly ramping-up 3-tier solutions in AWS!

This repository contains a collection of Terraform modules that aim to make it easier and faster for customers to get started with a 3-tier-architecture in [AWS](https://aws.amazon.com/). It can be used to configure and manage a complete stack with
* a static website served from S3 via Cloudfront
* and containerized backend/API run on ECS
* and an RDS MySQL database
that is fully bootstrapped and correctly setup with best practices in mind.

## Getting Started

The easiest way to get started with Terra3 is to follow our [Getting Started guide](https://terra3.io/latest/getting-started/).

## Documentation

For complete project documentation, please visit our [documentation site](https://terra3.io/).

## Examples

To view examples for how you can leverage Terra3, please see the [examples](https://github.com/it-objects/terraform-aws-terra3/tree/main/examples) directory.

## Usage

The below demonstrates how you can leverage Terra to deploy a 3-tier-architecture, including a static website served via S3 and Cloudfront, a container (in this case an nginx for demo purposes). After a "terraform apply" a Cloudfront is shown which, after about 2 minutes" should redirect to the static website on root ("/") and the nginx container on ("/api").

```hcl
module "terra3_environment" {
  source  = "it-objects/terra3/aws"
  version = "0.9.0"

  solution_name = "example_solution"

  # required when using containers; not required when just using the static web application served from S3
  create_load_balancer = true
  nat                  = "NAT_INSTANCES"

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
  source = "it-objects/terra3/aws/modules/container"

  name = "backend_service"

  container_image  = "nginxdemos/hello"
  container_cpu    = 256
  container_memory = 512

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 80
  }]

  map_environment = {
    "my_var_name" : "my_var_value",
    "my_var_name2" : "my_var_value2",
  }

  readonlyRootFilesystem = false # disable because of entrypoint script
}
```
