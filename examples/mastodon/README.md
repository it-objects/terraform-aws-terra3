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

The easiest way to get started with Mastodon with Terra3 is to follow this guide!

1. Create an AWS Route53 Hosted Zone and publish it. Take a note of the AWS Hosted Zone, as you need to fill it in in step 2.
2. Update the terraform.tfvars file. It requires you to generate some secret keys and add an SMTP server to send emails. For latter, you can either use AWS SES or a third party service such as [mailgun](https://www.mailgun.com/)If unsure what to fill in, please visit the official [Mastodon documentation](https://docs.joinmastodon.org/admin/config/)
3. Run "terraform apply"
4. It'll take about 10 minutes to provision everything
5. Test your Mastodon instance using the URL <solution_name>.<aws_hosted_zone_domain_name>
6. On the website, register a new user and confirm your email address via the confirmation mail you've been sent
7. Determine your cluster name and task arn using the AWS console
8. The final step is promote this user to an admin user using tootctl. For this, exec into your web container with the following command:

```
# Make sure you're logged in to your AWS account to be able to use the aws cli
# Add the cluster name and task arn from your AWS console from step 7 and add these to the command below
$ aws ecs execute-command --interactive --command "/bin/bash" --cluster <CLUSTER_NAME> --task <TASK_ARN>

# It should look something like this:
$ aws ecs execute-command --interactive --command "/bin/bash" --cluster terra3-mastodon-cluster --task arn:aws:ecs:eu-central-1:111111111111:task/terra3-mastodon-cluster/1f5a00a38bea43459cc1071fc5b14280

# A shell in your container should open. Run tootctl to promote your user
$ tootctl accounts modify <USERNAME_FROM_STEP_6> --role Admin --confirm

# It takes tootctl some seconds before it confirms with 'OK'.
# --confirm is only needed if your SMTP email server is not correctly setup and you weren't able to receive a confirmation email
```

Remark: You can find more documentation on tootctl [here](https://docs.joinmastodon.org/admin/tootctl/).

9. Go back to your browser and reload the page. You should now see all additional admin options.
10. You've just setup a scalable Mastodon server. Enjoy!

## Terra3 Documentation

To get more information on Terra3, please visit our [documentation site](https://terra3.io/).

## Additional Terra3 examples

To view additional examples for how you can leverage Terra3, please see the [examples](https://github.com/it-objects/terraform-aws-terra3/tree/main/examples) directory.

## About

This project is maintained and published with :heart: by [it-objects GmbH](https://it-objects.de/cloud/).

We're a full-service software development company based in Essen, Germany & Lisbon, Portugal.

[Apply for a job](https://www.it-objects.de/jobs/), or hire us to help with your software development, and all things cloud and devops.
