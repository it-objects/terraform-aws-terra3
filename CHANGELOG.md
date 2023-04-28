# Changelog

All notable changes to this project will be documented in this file.

## [1.10.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.9.0...v1.10.0) (2023-04-28)


### Features

* add environment sleep feature which allows to scale down the environment after a provided schedule to save costs in e.g. lower stages ([0fe9358](https://github.com/it-objects/terraform-aws-terra3/commit/0fe935818b94f1339c5020d0ce8fff5722d8020b))

## [1.9.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.8.0...v1.9.0) (2023-04-27)


### Features

* add alias domain ([#32](https://github.com/it-objects/terraform-aws-terra3/issues/32)) ([3a71814](https://github.com/it-objects/terraform-aws-terra3/commit/3a71814f56d67a87b08aedf4884db63388b9deba))

## [1.8.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.7.0...v1.8.0) (2023-04-27)


### Features

* enabled S3 access control lists (ACLs) for S3 buckets ([#31](https://github.com/it-objects/terraform-aws-terra3/issues/31)) ([9201a3f](https://github.com/it-objects/terraform-aws-terra3/commit/9201a3fba70a2e5824a877249d0cd60a19e4464f))

## [1.7.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.6.0...v1.7.0) (2023-04-25)


### Features

* Added bucket ownership control to enable ACLs. ([#29](https://github.com/it-objects/terraform-aws-terra3/issues/29)) ([b19aae0](https://github.com/it-objects/terraform-aws-terra3/commit/b19aae05ebd5cb625244f196668b1b9d64036bec))

## [1.6.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.5.0...v1.6.0) (2023-04-13)


### Features

* updated to current version of rds for mysql database. ([4d7a3b3](https://github.com/it-objects/terraform-aws-terra3/commit/4d7a3b3161c570f3011ca1997aeecce5856ef61c))

## [1.5.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.4.0...v1.5.0) (2023-02-24)


### Features

* added option to enable alert based on ecs running task count ([#28](https://github.com/it-objects/terraform-aws-terra3/issues/28)) ([69f4690](https://github.com/it-objects/terraform-aws-terra3/commit/69f4690cbd2c181e895ebc93cacf67f583c57f09))

## [1.4.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.3.0...v1.4.0) (2023-02-24)


### Features

* added more options to configure the database ([#27](https://github.com/it-objects/terraform-aws-terra3/issues/27)) ([586de72](https://github.com/it-objects/terraform-aws-terra3/commit/586de7298b577c237bea90fe03c5fbd68bb8c07d))

## [1.3.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.2.0...v1.3.0) (2023-02-23)


### Features

* activate option for single AZ ([cb705d3](https://github.com/it-objects/terraform-aws-terra3/commit/cb705d398578fd02245c4d8423ac519a079bbcfa))
* add option to disable custom error messages in Cloudfront in cases where API responses are masked by a custom error response on 404. ([7b838bd](https://github.com/it-objects/terraform-aws-terra3/commit/7b838bd4381f861ca2221e83d26e6cc09e0ddf6d))

## [1.2.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.1.0...v1.2.0) (2023-02-23)


### Features

* add option to set subnet tags as required by eks and elb ([ac6cd0f](https://github.com/it-objects/terraform-aws-terra3/commit/ac6cd0fa7f0b4d934bc4f551e79b858cd9f80d44))

## [1.1.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.0.0...v1.1.0) (2023-02-13)


### Features

* **vpc:** output VPC related ids ([8532b41](https://github.com/it-objects/terraform-aws-terra3/commit/8532b4190768b1a59f1cd244ecf7f5647a0e7355))

## [1.0.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.26.0...v1.0.0) (2023-02-08)


### ⚠ BREAKING CHANGES

* Terra3 v1.0 GA

### Miscellaneous Chores

* reverting change of example ([28a0c44](https://github.com/it-objects/terraform-aws-terra3/commit/28a0c44023d3d9caaa3ebca907e5de97698c3908))

## [0.26.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.25.1...v0.26.0) (2023-02-08)


### Features

* **modules:** update modules to latest versions ([39486fd](https://github.com/it-objects/terraform-aws-terra3/commit/39486fd80a221e84292ab2d8659f6feda53516d9))

### [0.25.1](https://github.com/it-objects/terraform-aws-terra3/compare/v0.25.0...v0.25.1) (2023-02-08)


### Bug Fixes

* **alb:** fix issue when application load balancer is disabled and remove workaround for example 1 ([efa593c](https://github.com/it-objects/terraform-aws-terra3/commit/efa593c3f976bca3c07511f38316ba6f8cf4f509))

## [0.25.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.24.2...v0.25.0) (2023-02-08)


### Features

* **ecr:** add parameter that allows to add a custom ECR name. per default, the solution name is taken. ([bb2f829](https://github.com/it-objects/terraform-aws-terra3/commit/bb2f829ae7dbd167690281b5dab1e81b77807e73))

### [0.24.2](https://github.com/it-objects/terraform-aws-terra3/compare/v0.24.1...v0.24.2) (2023-02-06)


### Bug Fixes

* expose more output variables required for using gitlab_aws_oidc ([0a30d6d](https://github.com/it-objects/terraform-aws-terra3/commit/0a30d6dc44e1cc2a04980142ba9ed35b653e1ba6))

### [0.24.1](https://github.com/it-objects/terraform-aws-terra3/compare/v0.24.0...v0.24.1) (2023-02-06)


### Bug Fixes

* **cloudfront:** increase SPA compatibility by adding listbucket to S3 policy to avoid 403 and return 404 instead also to s3_static_website_bucket ([9275a42](https://github.com/it-objects/terraform-aws-terra3/commit/9275a427a86ebe2cd96ce50c754e9709b09ce457))

## [0.24.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.23.0...v0.24.0) (2023-02-06)


### Features

* **cloudfront:** increase SPA compatibility by adding listbucket to S3 policy to avoid 403 and return 404 instead also to s3_static_website_bucket ([f0922ad](https://github.com/it-objects/terraform-aws-terra3/commit/f0922adc3ef12937dfa9aae157f746c43ecec881))

## [0.23.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.22.0...v0.23.0) (2023-02-06)


### Features

* **cloudfront:** increase SPA compatibility by adding listbucket to S3 policy to avoid 403 and return 404 instead ([82b3d43](https://github.com/it-objects/terraform-aws-terra3/commit/82b3d43c2a03ae9c9543f598505e9d997681d32c))

## [0.22.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.21.0...v0.22.0) (2023-02-03)


### Features

* **cdn:** adding option to add cloudfront function to s3 static website bucket ([7d242b6](https://github.com/it-objects/terraform-aws-terra3/commit/7d242b615054669db8757aa3bb056df694094252))


### Bug Fixes

* **examples:** examples with create_load_balancer = false currently don't work with latest version. This fixes this issue temporarily by pinning version to older version of Terra3 ([6051696](https://github.com/it-objects/terraform-aws-terra3/commit/60516963b934dd3c0b4a28d3702376737c1a8f82))

## [0.21.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.20.2...v0.21.0) (2023-01-30)


### Features

* adding switch for creating subdomain or use hosted zone's domain name ([fe739f8](https://github.com/it-objects/terraform-aws-terra3/commit/fe739f83f706a3ac94e1fb7b69779c96988147f2))

### [0.20.2](https://github.com/it-objects/terraform-aws-terra3/compare/v0.20.1...v0.20.2) (2023-01-30)


### Bug Fixes

* container definitions with certain log_configuration declarations were not accepted ([efba249](https://github.com/it-objects/terraform-aws-terra3/commit/efba249345de5385df20116c72d94bc9972f160a))

### [0.20.1](https://github.com/it-objects/terraform-aws-terra3/compare/v0.20.0...v0.20.1) (2023-01-27)


### Bug Fixes

* added default value of firelens container ([#26](https://github.com/it-objects/terraform-aws-terra3/issues/26)) ([74bf9d6](https://github.com/it-objects/terraform-aws-terra3/commit/74bf9d609dfd3ab9e294fd5c33a912cc84f22dce))

## [0.20.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.19.0...v0.20.0) (2023-01-27)


### Features

* added logconfiguration as configurable and firelensconfiguration as an option ([#25](https://github.com/it-objects/terraform-aws-terra3/issues/25)) ([8a0380b](https://github.com/it-objects/terraform-aws-terra3/commit/8a0380b02ab0d43a63ccb7f889d0bb5465788dcd))

## [0.19.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.18.0...v0.19.0) (2023-01-26)


### Features

* adding database credentials to SSM parameter. ([#24](https://github.com/it-objects/terraform-aws-terra3/issues/24)) ([af90a58](https://github.com/it-objects/terraform-aws-terra3/commit/af90a5893d37feafd92a8d6e2cc3d5b7e2f92dbc))

## [0.18.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.17.0...v0.18.0) (2023-01-25)


### Features

* adding configurations for memory_reservation and default_redirect_url ([e51988b](https://github.com/it-objects/terraform-aws-terra3/commit/e51988b1c947038bffc2df8b165cd5dd75f24ad9))

## [0.17.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.16.1...v0.17.0) (2023-01-24)


### Features

* adding option for injecting secrets to app_component ([#22](https://github.com/it-objects/terraform-aws-terra3/issues/22)) ([d7cc43a](https://github.com/it-objects/terraform-aws-terra3/commit/d7cc43a170df501dfd261704ab90cb272130a9ab))

### [0.16.1](https://github.com/it-objects/terraform-aws-terra3/compare/v0.16.0...v0.16.1) (2023-01-24)


### Bug Fixes

* avoid error if no S3 solution bucket is created ([2b3f1a2](https://github.com/it-objects/terraform-aws-terra3/commit/2b3f1a26cdc01eb9e59d75a32021575785cf1c1f))

## [0.16.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.15.0...v0.16.0) (2023-01-23)


### Features

* added output arn of s3 solution bucket. ([#21](https://github.com/it-objects/terraform-aws-terra3/issues/21)) ([94c15d7](https://github.com/it-objects/terraform-aws-terra3/commit/94c15d7f129fb85feee719cd7454147be6340021))

## [0.15.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.14.0...v0.15.0) (2023-01-19)


### Features

* allow setting up two tf states, one for infra scope and one for application scope to reduce blast radius ([cb223a0](https://github.com/it-objects/terraform-aws-terra3/commit/cb223a00a3faa6a4cfa35f96ba42fe71cf896f2f))

## [0.14.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.13.0...v0.14.0) (2023-01-17)


### Features

* add option to enable AWS ECS also with EC2 instances instead of Fargate ([4dea29c](https://github.com/it-objects/terraform-aws-terra3/commit/4dea29c129906c1cc402af4197f854a57225a779))

## [0.13.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.12.0...v0.13.0) (2023-01-17)


### Features

* allow to use Terra3 with an existing VPC ([3c473a9](https://github.com/it-objects/terraform-aws-terra3/commit/3c473a9a90b7de9c66f55e988f2484c2a151d15b))

## [0.12.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.11.2...v0.12.0) (2023-01-17)


### Features

* adding scheduled api calls for e.g. maintenance activities (currently limited to unauthorized GET requests) ([b7ef9b9](https://github.com/it-objects/terraform-aws-terra3/commit/b7ef9b9e756c77b908586964a995c94b89848071))

### [0.11.2](https://github.com/it-objects/terraform-aws-terra3/compare/v0.11.1...v0.11.2) (2022-12-29)


### Bug Fixes

* storing alb logs disabled. ([96b976b](https://github.com/it-objects/terraform-aws-terra3/commit/96b976b0f23d45c2a7b0c13dd36ffdea533ca75b))

### [0.11.1](https://github.com/it-objects/terraform-aws-terra3/compare/v0.11.0...v0.11.1) (2022-12-29)


### Bug Fixes

* added switch of alb logs in s3 bucket ([9d5a1be](https://github.com/it-objects/terraform-aws-terra3/commit/9d5a1bef80bcf6dc10671b277eee8dccc1658275))

## [0.11.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.10.0...v0.11.0) (2022-12-20)


### Features

* ECS cluster option for using EC2 added ([3cba40e](https://github.com/it-objects/terraform-aws-terra3/commit/3cba40efa39bcc54620f5411d3f5ed044e12da09))

## [0.10.0](https://github.com/it-objects/terraform-aws-terra3/compare/v0.9.7...v0.10.0) (2022-12-08)


### Features

* add option field to create a public_read_only S3 solution bucket ([9b20902](https://github.com/it-objects/terraform-aws-terra3/commit/9b209028da6eddbbd12f00b2c8827c2ea3744ce4))
* add option to make solution bucket available via Cloudfront ([7ae7baf](https://github.com/it-objects/terraform-aws-terra3/commit/7ae7baf9071b3350c48b996509ef83c2b93768ad))
* add option to select Postgres ([c01e8e5](https://github.com/it-objects/terraform-aws-terra3/commit/c01e8e51bb5cffeeb8f15921c3440843959898b5))
* add switch for enabling ecs_exec ([d83366a](https://github.com/it-objects/terraform-aws-terra3/commit/d83366a8357a207d068bd497f3862965e546d804))
* add switch per app_component to enable access to S3 solution bucket via IAM roles ([b6eedad](https://github.com/it-objects/terraform-aws-terra3/commit/b6eedadee14fc5a92ed31845d074920aa8cf6c00))
* add switch to enable application specific S3 bucket ([814f414](https://github.com/it-objects/terraform-aws-terra3/commit/814f41441eca06c20626f72b47335c3dcc96e28e))
* add switch to enable Redis ([af3725a](https://github.com/it-objects/terraform-aws-terra3/commit/af3725a2d2d0cc6b477b5eb5bb70e7f359c0050d))
* adding Mastodon as example for using Terra3 ([e19f822](https://github.com/it-objects/terraform-aws-terra3/commit/e19f8229230797dfd663db2e8d85b40a0c5ddd00))
* adding option for specifying lb health check grace period ([1f050b0](https://github.com/it-objects/terraform-aws-terra3/commit/1f050b0cc4ea30c7bba53aa25440421439b94ab9))
* **mastodon:** Mastodon with terra3 example + documentation completed ([58be246](https://github.com/it-objects/terraform-aws-terra3/commit/58be2464e722a2980d45f118dd01505d71bb5d68))
* **mastodon:** Mastodon with terra3 example + documentation completed ([2407bf9](https://github.com/it-objects/terraform-aws-terra3/commit/2407bf9d52d9a1cfbc9a4de11754c4b5717025fc))
* move db and redis in separate subnets ([ec8292d](https://github.com/it-objects/terraform-aws-terra3/commit/ec8292d05c69610ea6d580ac9e4206048f5f152f))
* **nat:** add several new NAT Gateway options ([#4](https://github.com/it-objects/terraform-aws-terra3/issues/4)) ([0377345](https://github.com/it-objects/terraform-aws-terra3/commit/0377345ae4704885c9c1b7d60f5b69a535d1364e))
* provide a more flexible way to define multiple cloudfront behaviours for the s3 solution bucket ([38295bf](https://github.com/it-objects/terraform-aws-terra3/commit/38295bf2fc75c3a894c9bdb34064618787e181e7))


### Bug Fixes

* clean-up unnecessary depends_on declaration which caused unnecessary redeployments from time to time ([766e40c](https://github.com/it-objects/terraform-aws-terra3/commit/766e40c8d4dcd92557175eb6ca39ee47028db0a9))
* issue when creating example from website with no cloudfront behaviours explicitly set ([e2078f1](https://github.com/it-objects/terraform-aws-terra3/commit/e2078f1e425954eaf54021074d55d6f6c3f97c06))
* issue with dependencies on ssm parameters ([f48d504](https://github.com/it-objects/terraform-aws-terra3/commit/f48d50401526e0eb730ee81a542e6a0550c93bb9))
* set default creation of elasticache redis to false ([4503b2b](https://github.com/it-objects/terraform-aws-terra3/commit/4503b2b9828094ef8fab9182b7f67f03fd0894b7))
* use a solution specific elasticache subnet group name to avoid name collisions ([a4d2005](https://github.com/it-objects/terraform-aws-terra3/commit/a4d20050ea0bd73da54d3b2b8134350021f4c56f))

### [0.9.7](https://github.com/it-objects/terraform-aws-terra3/compare/v0.9.6...v0.9.7) (2022-11-02)


### Bug Fixes

* **tfsec:** add ignores for 2 new medium tfsec findings ([78b43df](https://github.com/it-objects/terraform-aws-terra3/commit/78b43dfeb43bfaeb2b885432584637526a06f045))

### [0.9.6](https://github.com/it-objects/terraform-aws-terra3/compare/v0.9.5...v0.9.6) (2022-10-21)


### Features

* **terra3:** add more descriptions to the module's parameters and add proper validation for the solution_name ([6870331](https://github.com/it-objects/terraform-aws-terra3/commit/6870331c2510a0144fc4c4edd1b4423ba3bdd33f))


### Bug Fixes

* **examples:** make example 3 consume the Terra3 module from a relative path to ensure the right version being picked. ([c59d23e](https://github.com/it-objects/terraform-aws-terra3/commit/c59d23e09ee7cc7903c6fc31b4ad9040e39dafad))

### [0.9.5](https://github.com/it-objects/terraform-aws-terra3/compare/v0.9.4...v0.9.5) (2022-10-21)


### Features

* **examples:** adding full URLs as outputs to ease testing the results ([24a09ea](https://github.com/it-objects/terraform-aws-terra3/commit/24a09ea4d0a58f5459a0b2d64ea6810aa1770fc6))


### Bug Fixes

* **examples:** change readonlyRootFilesystem default to optional true as otherwise this causes nginx and other images to fail and working with the module more difficult ([b3fdd6f](https://github.com/it-objects/terraform-aws-terra3/commit/b3fdd6fd4755144b0914da4556ee093da4da1b84))
* **examples:** removing version pinning as this caused an issue with the example from the README.md using an old version ([0c83396](https://github.com/it-objects/terraform-aws-terra3/commit/0c833965dbf21e749da032eb3044eaa2eb8a5c3d))
