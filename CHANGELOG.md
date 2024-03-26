# Changelog

All notable changes to this project will be documented in this file.

### [1.34.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.34.0...v1.34.1) (2024-03-26)


### Bug Fixes

* **deps:** in aws vpc module set map_public_ip_on_launch to true to stay backwards compatible ([0c18227](https://github.com/it-objects/terraform-aws-terra3/commit/0c18227e399abbaec507c560d7e87390b677099c))

## [1.34.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.33.1...v1.34.0) (2024-03-25)


### Features

* **deps:** update internal Terraform module deps ([06ec161](https://github.com/it-objects/terraform-aws-terra3/commit/06ec16140748953852b54985b2af8ee6baf9ada2))

### [1.33.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.33.0...v1.33.1) (2024-02-26)


### Bug Fixes

* updated default rds database engine version ([#46](https://github.com/it-objects/terraform-aws-terra3/issues/46)) ([7be0ee8](https://github.com/it-objects/terraform-aws-terra3/commit/7be0ee84bac04811bc73fa4e4ebd060863b2fe4c))

## [1.33.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.32.0...v1.33.0) (2024-02-23)


### Features

* added parameters to configure rds database engine version ([#45](https://github.com/it-objects/terraform-aws-terra3/issues/45)) ([d2b7304](https://github.com/it-objects/terraform-aws-terra3/commit/d2b7304a6d59e3ad93e67060a4827322ee5bd8bc))

## [1.32.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.31.0...v1.32.0) (2024-02-21)


### Features

* added option to support SPA without default error redirect by using Lambda@Edge ([#44](https://github.com/it-objects/terraform-aws-terra3/issues/44)) ([cf1d990](https://github.com/it-objects/terraform-aws-terra3/commit/cf1d99068a89226f27f569e9b0a67332f530075e))

## [1.31.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.30.2...v1.31.0) (2024-01-24)


### Features

* improvements in global scale down feature (TERRA3-124, TERRA3-126, TERRA3-127, TERRA3-128, TERRA3-129) ([#43](https://github.com/it-objects/terraform-aws-terra3/issues/43)) ([df7909e](https://github.com/it-objects/terraform-aws-terra3/commit/df7909e3418042ca2859a25fb0da5f19ff301a3f))

### [1.30.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.30.1...v1.30.2) (2023-12-20)


### Bug Fixes

* updated timeout of lambda functions in environment feature ([a842522](https://github.com/it-objects/terraform-aws-terra3/commit/a8425221c08fdc121b3e1645818a89dc1e9a6f8f))

### [1.30.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.30.0...v1.30.1) (2023-12-19)


### Bug Fixes

* unabled default resource creation of environment hibernation feature ([#42](https://github.com/it-objects/terraform-aws-terra3/issues/42)) ([5c8a434](https://github.com/it-objects/terraform-aws-terra3/commit/5c8a4341f94e700964fc47249935ed716bedc367))

## [1.30.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.29.1...v1.30.0) (2023-11-28)


### Features

* added environment hibernation mini admin website ([#37](https://github.com/it-objects/terraform-aws-terra3/issues/37)) ([57da5f3](https://github.com/it-objects/terraform-aws-terra3/commit/57da5f3561e65676ce4042626db5f39dae6b8c26))

### [1.29.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.29.0...v1.29.1) (2023-11-21)


### Bug Fixes

* remove unnecessary code ([66b09e4](https://github.com/it-objects/terraform-aws-terra3/commit/66b09e44b2a4b07a58fd2c419a7a7f43ed0e8c02))

## [1.29.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.28.0...v1.29.0) (2023-11-21)


### Features

* adding options for creating a KMS to be used e.g. for SOPS ([a46d3ad](https://github.com/it-objects/terraform-aws-terra3/commit/a46d3ad0c39f0dc8fa6bd817d10289306dac2112))
* **ecr:** output all declared ECR's ([b91c544](https://github.com/it-objects/terraform-aws-terra3/commit/b91c5440d4c4142d3426e88c48167321ead65c9c))


### Bug Fixes

* **ecr:** if ecr is not enabled make output work ([f22deb5](https://github.com/it-objects/terraform-aws-terra3/commit/f22deb5b5a407200a23e6362b71f1d56bb09e830))

## [1.28.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.27.2...v1.28.0) (2023-11-08)


### Features

* **alb:** make deletion protection configurable ([dc2a756](https://github.com/it-objects/terraform-aws-terra3/commit/dc2a75674edc3c8c2937e940f2f4b094240ecbe3))
* **rds:** make RDS more configurable ([2f8c5e2](https://github.com/it-objects/terraform-aws-terra3/commit/2f8c5e25e3e88d7ee5ce161fb2169aeba8d06da0))


### Bug Fixes

* **alb:** fixed issue when alb logs are enabled ([f237929](https://github.com/it-objects/terraform-aws-terra3/commit/f2379290ab9fc1ec08422a6d0a3ca7ba4977e3cf))

### [1.27.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.27.1...v1.27.2) (2023-11-06)


### Bug Fixes

* **alerting:** fix state drift due to unnecessary explicit IAM role given although it is identical with the default ([7ba13a9](https://github.com/it-objects/terraform-aws-terra3/commit/7ba13a9a1c34bbd44784c0917b2681947eb29f0e))

### [1.27.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.27.0...v1.27.1) (2023-10-31)


### Bug Fixes

* **bastion:** remove dynamic fetching of latest ami; it is pinned now and should only updated along new terra3 versions. Otherwise we'll experience continuous state drift. ([8d4fbba](https://github.com/it-objects/terraform-aws-terra3/commit/8d4fbbad2b8b390a79852c5b9e5742821e749ea7))

## [1.27.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.26.1...v1.27.0) (2023-10-20)


### Features

* added output of s3 bucket name. ([f6f65ba](https://github.com/it-objects/terraform-aws-terra3/commit/f6f65ba3ce4b76c2d89f773921621f696d060f68))

### [1.26.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.26.0...v1.26.1) (2023-09-18)


### Bug Fixes

* added iam policy version for container-based cron job ([2ddf4bf](https://github.com/it-objects/terraform-aws-terra3/commit/2ddf4bf91a63385d0c97af83275ea7b05b379ba9))
* updated rds engine version for mysql ([20ca2bf](https://github.com/it-objects/terraform-aws-terra3/commit/20ca2bfe303e79618dc85ab2fd20fea837c75d8f))
* updated solution name ([c45fb67](https://github.com/it-objects/terraform-aws-terra3/commit/c45fb676b23193e869b4091cb8d9879b4c2e46c3))

## [1.26.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.25.1...v1.26.0) (2023-09-15)


### Features

* Introducing ECS Fargate container-based cron jobs triggered by a step function. It only requires a single line of configuration. See also the ecs_cronjob in the examples subfolder. ([d6af032](https://github.com/it-objects/terraform-aws-terra3/commit/d6af032b2c7e14ec0fa9b2622b605cc284a13b53))

### [1.25.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.25.0...v1.25.1) (2023-09-13)


### Bug Fixes

* fixes issue with path_mapping reconciliation when app_components don't have the optional path_mapping defined ([a2ace80](https://github.com/it-objects/terraform-aws-terra3/commit/a2ace80add918d44d9b39f6569d43f45b77f29e3))

## [1.25.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.24.0...v1.25.0) (2023-09-12)


### Features

* added ecr names variable. ([0719da6](https://github.com/it-objects/terraform-aws-terra3/commit/0719da6d3f5eb4df61e01a50c91087c1e77dacf0))
* implemented logic for creating more than one ecr repository based on the number of names specified by user. ([b1990a1](https://github.com/it-objects/terraform-aws-terra3/commit/b1990a1c26268588d966152532b890b53f87cfd0))
* updated db subnet group name with solution name ([8ad8c7a](https://github.com/it-objects/terraform-aws-terra3/commit/8ad8c7a52d6a5c072974f79ae2dd6e0722733125))

## [1.24.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.23.0...v1.24.0) (2023-09-11)


### Features

* added ssm parameter for private subnets. ([78d20f3](https://github.com/it-objects/terraform-aws-terra3/commit/78d20f35b8687850a20da9532f3421928b9a4dfc))
* updated subnet value accessing form tag to parameter. ([bb31d01](https://github.com/it-objects/terraform-aws-terra3/commit/bb31d01084dd594b4109d687806bc17c43466a97))

## [1.23.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.22.0...v1.23.0) (2023-09-06)


### Features

* added configurations for db subnet group while using existing vpc. ([c4cbdd5](https://github.com/it-objects/terraform-aws-terra3/commit/c4cbdd549ca7cb397d9d6f5320e00bb6acd6d4dc))
* added list of private subnets to the launch bastion host. ([8dc7560](https://github.com/it-objects/terraform-aws-terra3/commit/8dc7560b0b1fbb3095ee01bd57f2640a3683a452))
* added subnets as a variable. ([096fb7e](https://github.com/it-objects/terraform-aws-terra3/commit/096fb7eed3eae0b87533628874bd51236ae69a38))
* added variable of external database cidr. ([f03e476](https://github.com/it-objects/terraform-aws-terra3/commit/f03e476e784fd005db1b082d861d76076bbf3ba6))
* removed data resource of vpc and added ami data resource to get latest amazon image. ([74decb7](https://github.com/it-objects/terraform-aws-terra3/commit/74decb739768a0b9b40eeddadfefae99d2af81a8))
* updated ami id via data resource, latest volume type and added subnets as a variable. ([364575a](https://github.com/it-objects/terraform-aws-terra3/commit/364575a709a4b3b9165b37315b3e8b538d817b11))

## [1.22.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.21.0...v1.22.0) (2023-09-04)


### Features

* add option to disable VPC endpoint for S3 ([8b3c7fd](https://github.com/it-objects/terraform-aws-terra3/commit/8b3c7fd7eda02796984ba5485ce5da1fd9a21529))
* make terra3 module work in other regions than eu-central-1 ([3496ea1](https://github.com/it-objects/terraform-aws-terra3/commit/3496ea1174761bbaec92d75b390471ce1359c596))

## [1.21.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.20.2...v1.21.0) (2023-08-28)


### Features

* enabled access to ecr repo for more than one account ([#38](https://github.com/it-objects/terraform-aws-terra3/issues/38)) ([d08a191](https://github.com/it-objects/terraform-aws-terra3/commit/d08a1911fc4e3c003d776b1327853a51e7be9fb4))

### [1.20.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.20.1...v1.20.2) (2023-08-22)


### Bug Fixes

* **cloudfront-url-signing:** write correct Cloudfront key pair id into SSM parameter ([2c01476](https://github.com/it-objects/terraform-aws-terra3/commit/2c01476c13966c55d678840831a5ca582f34b606))

### [1.20.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.20.0...v1.20.1) (2023-08-22)


### Bug Fixes

* **cloudfront-url-signing:** write correct Cloudfront key pair id into SSM parameter ([e6fe2ee](https://github.com/it-objects/terraform-aws-terra3/commit/e6fe2ee6586cd66b4ff1337c931f11114b6c34e0))

## [1.20.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.19.0...v1.20.0) (2023-08-17)


### Features

* also works now for two TF state approach - multiple containers are now reachable via Cloudfront under different top level directory paths ([7ffb788](https://github.com/it-objects/terraform-aws-terra3/commit/7ffb78833b34be663587c040368ebd8a2e57441a))

## [1.19.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.18.0...v1.19.0) (2023-08-17)


### Features

* cloudfront url signing ([cd23726](https://github.com/it-objects/terraform-aws-terra3/commit/cd23726fa28cf950e8383b4bb2f0756e771cd507))

## [1.18.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.17.0...v1.18.0) (2023-08-16)


### Features

* have the loadbalancer prios be calculated automatically according to the app_components' sequence ([a4c7524](https://github.com/it-objects/terraform-aws-terra3/commit/a4c7524a13d7c98730119bb147c5e26415003c8c))
* multiple containers are now reachable via Cloudfront under different top level directory paths ([dcf3a9d](https://github.com/it-objects/terraform-aws-terra3/commit/dcf3a9df31b533092407ca38fc89dc58cb0f76e0))

## [1.17.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.16.0...v1.17.0) (2023-07-05)


### Features

* make lambda function idempotent and aware of hibernation state ([#36](https://github.com/it-objects/terraform-aws-terra3/issues/36)) ([a65c501](https://github.com/it-objects/terraform-aws-terra3/commit/a65c50165bdcc2415a4d3304ed49681a31844a12))

## [1.16.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.15.0...v1.16.0) (2023-06-20)


### Features

* moved eventbridge parameters into lambda function by using ssm parameter ([#35](https://github.com/it-objects/terraform-aws-terra3/issues/35)) ([b9e68b9](https://github.com/it-objects/terraform-aws-terra3/commit/b9e68b9afe73a71e5093f282b5100bf94f2470c6))

## [1.15.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.14.3...v1.15.0) (2023-06-07)


### Features

* **global-scaledown-option:** scaledown option with separate tf state ([d8413a3](https://github.com/it-objects/terraform-aws-terra3/commit/d8413a378c72a7bf197d152ba7db1d2ce0c2d40e))

### [1.14.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.14.2...v1.14.3) (2023-06-07)


### Bug Fixes

* updated aws provider version. ([9daf64a](https://github.com/it-objects/terraform-aws-terra3/commit/9daf64a492873c4ae65235b3f0843b5fc5e146c6))

### [1.14.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.14.1...v1.14.2) (2023-05-26)


### Bug Fixes

* **aws-provider:** pinning aws provider to versions below 5.0.0 as these cause issues with aws vpc module ([4b1a01d](https://github.com/it-objects/terraform-aws-terra3/commit/4b1a01de20c30858a78f93589c5190f6837b25ef))

### [1.14.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.14.0...v1.14.1) (2023-05-26)


### Bug Fixes

* **vpc-module:** adding version pinning to aws vpc module ([f321290](https://github.com/it-objects/terraform-aws-terra3/commit/f3212902411c8c1bfa6851f490f954defc7adee1))

## [1.14.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.13.0...v1.14.0) (2023-05-26)


### Features

* **s3-endpoint:** giving public subnet also access to s3 gateway endpoint ([14caf9e](https://github.com/it-objects/terraform-aws-terra3/commit/14caf9e42ed08e2c4da7382913baab2314e3b3b0))

## [1.13.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.12.0...v1.13.0) (2023-05-23)


### Features

* **hibernate:** re-enable deprecated scaledown option ([c83f637](https://github.com/it-objects/terraform-aws-terra3/commit/c83f63796998152c3a48c954a506bee57a1c8430))

## [1.12.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.11.0...v1.12.0) (2023-05-23)


### Features

* **hibernate:** re-enable deprecated scaledown option ([bf4c470](https://github.com/it-objects/terraform-aws-terra3/commit/bf4c470c77e86450c01b3ba9b87908bb7fe1b372))

## [1.11.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.10.0...v1.11.0) (2023-05-04)


### Features

* autoscaling of fargate container based on cpu and memory utilisation ([#14](https://github.com/it-objects/terraform-aws-terra3/issues/14)) ([fb3a8fc](https://github.com/it-objects/terraform-aws-terra3/commit/fb3a8fc5ac6e9f8907f648377c84468f0b97733a))

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
