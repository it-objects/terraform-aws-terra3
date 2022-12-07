# Terra3

[![pre-commit](https://github.com/it-objects/terraform-aws-terra3/actions/workflows/pre-commit.yaml/badge.svg)](https://github.com/it-objects/terraform-aws-terra3/actions/workflows/pre-commit.yaml)

Mastodon with Terra3 - Quickly ramping-up a Mastodon instance in AWS!

This directory contains a pre-configured Terra3 instance that spawns a Mastodon server. It serves as validation for the Terra3 module
but can also be used as foundation for running a Mastodon server in production.

It consists of
* a container runtime (ECS) to run all Mastodon services such as the web, streaming API and sidekiq container
* an S3 solution bucket to store und serve uploaded media assets
* all fronted by a CDN using AWS Cloudfront
* an RDS Postgres database
* an Elasticache Redis

Using Terra3 makes the required code base small and almost effortless to glue all components together. It includes all batteries and has considered best practices out-of-the-box.

## Getting Started

The easiest way to get started with Mastodon with Terra3 is to follow this guide.

1. Create an AWS Route53 Hosted Zone and publish it. Take a note of the AWS Hosted Zone, as you need to fill it in in step 2.
2. Update the terraform.tfvars file. It requires you to generate some secret keys and add an SMTP server to send emails. For latter, you can either use AWS SES or a third party service such as [mailgun](https://www.mailgun.com/)If unsure what to fill in, please visit the official [Mastodon documentation](https://docs.joinmastodon.org/admin/config/)
3. Run "terraform apply"
4. It'll take about 20 minutes to provision everything
5. Test it using the URL <solution_name>.<aws_hosted_zone_domain_name>

## Terra3 Documentation

To get more information on Terra3, please visit our [documentation site](https://terra3.io/).

## Additional Terra3 examples

To view additional examples for how you can leverage Terra3, please see the [examples](https://github.com/it-objects/terraform-aws-terra3/tree/main/examples) directory.

## About

This project is maintained and published with :heart: by [it-objects GmbH](https://it-objects.de/cloud/).

We're a full-service software development company based in Essen, Germany & Lisbon, Portugal.

[Apply for a job](https://www.it-objects.de/jobs/), or hire us to help with your software development, and all things cloud and devops.
