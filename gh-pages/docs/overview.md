Overview
========

Welcome to Terra3 - An opinionated Terraform module for ramping-up 3-tier architectures in AWS in no time!

This repository contains a collection of Terraform modules that aim to make it easier and faster for customers to get started with a 3-tier-architecture in [AWS](https://aws.amazon.com/). It can be used to configure and provision a complete stack with

*   a static website served from S3 and AWS Cloudfront

*   a containerized backend/API running on AWS ECS

*   an AWS RDS MySQL/Postgres database

*   an AWS ElastiCache Redis

It is the result of many projects we did for customers with similar requirements. And rather than starting from scratch
with every project, we've created reusable Terraform modules. What started as an internal library, now evolved into
a single module we'd like to share and to give back to the community as open source.

**Features**

These are module features that allow cloud engineers to customize the AWS infrastructure setup, mostly by just setting the appropriate flag.

* Pre-configured NAT instance as optional low-cost alternative to NAT Gateway

* Reasonable defaults such as "Enabled VPC Gateway endpoint for S3", "account-wide S3/EBS encryption"

* Database access for devs without SSH but via an SSM enabled bastion host

* ECS Exec to quickly shell into a container in a debug stage

* Optional multi-state Terraform to separate infrastructure from application deployment using AWS Parameter Store

* Least privileged IAM roles and security groups settings

* Transport encryption between Cloudfront and the Application Loadbalancer (if custom_domain is enabled)

* and many more...


What is Terra3
--------------

In its full-blown version it results in this AWS infrastructure setup:

![](attachments/61276161/62128139.png)

For now, please visit our [getting started](https://terra3.io/getting-started.html) for a step-by-step walk-through
to understand what different aspects Terra3 has to offer. We're planning to extend this documentation as a
blog series, that will highlight the different features with each post. So stay tuned.

What can I do with this solution?
---------------------------------

You can use it

*   as ramp-up to quickly see your website or container run on AWS

*   as base for your next project to skip the nitty-gritty grunt work

*   for educational purposes
