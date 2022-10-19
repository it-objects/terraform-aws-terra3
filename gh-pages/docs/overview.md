Overview
========

Welcome to Terra3 - An opinionated Terraform module for quickly ramping-up 3-tier solutions in AWS!

This repository contains a collection of Terraform modules that aim to make it easier and faster for customers to get started with a 3-tier-architecture in [AWS](https://aws.amazon.com/). It can be used to configure and manage a complete stack with

*   a static website served from S3 and AWS Cloudfront

*   a containerized backend/API running on AWS ECS

*   an AWS RDS MySQL database


The result is a _configurable_, fully bootstrapped, secure and preconfigured setup with best practices in mind.

**Configurable**

Besides the full-blown setup described above it is possible to simply use certain parts of it:

1.  A static website served from S3 and AWS Cloudfront only: Use this to host your static web application on AWS

2.  A containerized backend/API/web page running on AWS ECS only: Use this to host one or more services or APIs as containers in an AWS ECS cluster


**Opinionated**

It’s opinionated in the sense that the many decisions involved in such a setup were all made in a reasonable way, suiting the many customers where this is already running in production, where we think that this could also be an ideal starting point for others. Some examples of defaults are

*   ECS Fargate over ECS with EC2 instances and over EKS

*   Use Cloudfront to serve both static (S3) and dynamic (containers) content


What is Terra3
--------------

In its full-blown version it results in this AWS infrastructure setup:

![](attachments/61276161/62128139.png)

Motivation
-----------------------
Coming soon

What can I do with this solution?
---------------------------------

You can use it

*   as ramp-up to quickly see your website or container run on AWS

*   as base for your next project to skip the nitty gritty grunt work

*   for educational purposes
