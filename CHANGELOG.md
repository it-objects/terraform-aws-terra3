# Changelog

All notable changes to this project will be documented in this file.

## [1.50.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.49.3...v1.50.0) (2025-07-23)


### Features

* added ses access to infra oidc role ([082f37d](https://github.com/it-objects/terraform-aws-terra3/commit/082f37d9e08203f889a4bdea1f0440c52e567803))

### [1.49.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.49.2...v1.49.3) (2025-06-12)


### Bug Fixes

* **cronjob:** fix deprecations ([994a423](https://github.com/it-objects/terraform-aws-terra3/commit/994a42368bb2549dd176ee02a8acc2cacc03faa0))

### [1.49.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.49.1...v1.49.2) (2025-06-12)


### Bug Fixes

* **provider:** remove empty environment tag ([0ea86e5](https://github.com/it-objects/terraform-aws-terra3/commit/0ea86e593064427dc4ac4dae5259491af11e2387))

### [1.49.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.49.0...v1.49.1) (2025-05-26)


### Bug Fixes

* update variables' default values and get rid of obsolete variables ([f569520](https://github.com/it-objects/terraform-aws-terra3/commit/f569520829d136cee835d03d891d1893f5204d8b))

## [1.49.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.48.0...v1.49.0) (2025-05-23)


### Features

* **S3:** add parameter to enable Lambda@Edge for S3 static website ([#57](https://github.com/it-objects/terraform-aws-terra3/issues/57)) ([dd5e172](https://github.com/it-objects/terraform-aws-terra3/commit/dd5e1721d6fb269267687b6e195f2dae442c10cf))

## [1.48.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.47.2...v1.48.0) (2025-05-21)


### Features

* **lambda:** add Lambda@Edge support for SPAs in S3 static website ([#56](https://github.com/it-objects/terraform-aws-terra3/issues/56)) ([250988e](https://github.com/it-objects/terraform-aws-terra3/commit/250988ea960412ea6e169b90017550403c289049))

### [1.47.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.47.1...v1.47.2) (2025-04-11)


### Bug Fixes

* move aws provider declaration for useast1 to central provider.tf ([2637f37](https://github.com/it-objects/terraform-aws-terra3/commit/2637f37a176ac8da5d7b48a9399834835d095565))

### [1.47.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.47.0...v1.47.1) (2025-03-19)


### Bug Fixes

* disabled create_subdomain per default ([3f4cf99](https://github.com/it-objects/terraform-aws-terra3/commit/3f4cf995db47d1f424c992b30ed71f0d3a06a621))

## [1.47.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.46.0...v1.47.0) (2025-03-19)


### Features

* **logs:** add configurable expiry for ALB and CloudFront logs and add switch for CloudFront logs ([#55](https://github.com/it-objects/terraform-aws-terra3/issues/55)) ([c4de100](https://github.com/it-objects/terraform-aws-terra3/commit/c4de1003a1b32953d319c8e7c0b76ca38545c0d7))

## [1.46.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.10...v1.46.0) (2025-03-19)


### Features

* integrated fck-nat asg in global hibernation ([#54](https://github.com/it-objects/terraform-aws-terra3/issues/54)) ([d8f84b1](https://github.com/it-objects/terraform-aws-terra3/commit/d8f84b1d3b926060b3939fb6cc620218113a3861))

### [1.45.10](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.9...v1.45.10) (2025-03-07)


### Bug Fixes

* **fck-nat:** updated the route ([a9c4a82](https://github.com/it-objects/terraform-aws-terra3/commit/a9c4a8282e387323776f8073cf51b1e0ab078b3e))

### [1.45.9](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.8...v1.45.9) (2025-03-06)


### Features

* enable fck nat instance ([#53](https://github.com/it-objects/terraform-aws-terra3/issues/53)) ([9a5dd11](https://github.com/it-objects/terraform-aws-terra3/commit/9a5dd1122952b44f523d2c7cd1a8256828d40dda))


### Bug Fixes

* **fck-nat):** update instance type description ([800c603](https://github.com/it-objects/terraform-aws-terra3/commit/800c603614c2a7949d544beee32d8066d0ce1466))

### [1.45.8](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.7...v1.45.8) (2025-02-28)


### Bug Fixes

* **global-scale-down:** Lambda zip were not recreated, when found missing ([b305097](https://github.com/it-objects/terraform-aws-terra3/commit/b3050977a9c94f148930346b29dc442306a41836))

### [1.45.7](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.6...v1.45.7) (2025-02-28)


### Bug Fixes

* **cloudfront:** cope with empty cloudfront aliases ([12f3db5](https://github.com/it-objects/terraform-aws-terra3/commit/12f3db55f54b5dde082ba68814fccfdc49f512a4))

### [1.45.6](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.5...v1.45.6) (2025-02-27)


### Bug Fixes

* **cloudfront:** storing more cloudfront data in parameter store ([d7cb6b6](https://github.com/it-objects/terraform-aws-terra3/commit/d7cb6b6c3c424724657a6d4f6cb4548613af3e12))

### [1.45.5](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.4...v1.45.5) (2025-02-27)


### Bug Fixes

* **cloudfront:** storing more cloudfront data in parameter store ([f95c46e](https://github.com/it-objects/terraform-aws-terra3/commit/f95c46e459f0ec21dc816b25602135d93f58c657))

### [1.45.4](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.3...v1.45.4) (2025-01-15)


### Bug Fixes

* **gh-pages:** update deps ([e8b79ad](https://github.com/it-objects/terraform-aws-terra3/commit/e8b79ad8467388735dc3f38fd75632d7c379d11d))

### [1.45.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.2...v1.45.3) (2025-01-15)


### Bug Fixes

* **ses:** allow disabling the creation of SES user as this could stop the SES usage in environments with IAM restrictions ([79db32b](https://github.com/it-objects/terraform-aws-terra3/commit/79db32b340608a82c6f48963e3cec3f16ce047d6))

### [1.45.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.1...v1.45.2) (2024-12-31)


### Bug Fixes

* correct CloudFront distribution creation condition ([b78249c](https://github.com/it-objects/terraform-aws-terra3/commit/b78249ca7987a6d5ec7d4b01e80fe27fd74074e6))

### [1.45.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.45.0...v1.45.1) (2024-12-04)


### Bug Fixes

* **oidc:** managed_policy_arns is deprecated causing a warning in newer versions of the terraform cli. It's now being replaced using aws_iam_role_policy_attachment instead. ([147a98c](https://github.com/it-objects/terraform-aws-terra3/commit/147a98c29b91ceeefbb5bde8a35eb0a1fba20fe4))

## [1.45.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.44.3...v1.45.0) (2024-11-07)


### Features

* Make configurable runtime cpu architecture for FARGATE ([7bb3ae0](https://github.com/it-objects/terraform-aws-terra3/commit/7bb3ae06c4b3616925867c69ceed3474e8664e13))

### [1.44.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.44.2...v1.44.3) (2024-11-06)


### Bug Fixes

* disable overwrite parameter for cluster_type parameter ([33672a4](https://github.com/it-objects/terraform-aws-terra3/commit/33672a424a03dea25e8298d7b7550e92084d930c))

### [1.44.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.44.1...v1.44.2) (2024-11-06)


### Bug Fixes

* enable overwrite parameter for cluster_type parameter ([04c79c9](https://github.com/it-objects/terraform-aws-terra3/commit/04c79c99468f12794389fb00a84ecab3817bc9b3))

### [1.44.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.44.0...v1.44.1) (2024-11-06)


### Bug Fixes

* changed random postfix for s3 static website bucket to old one tp avoid recreation of bucket ([bdfaa02](https://github.com/it-objects/terraform-aws-terra3/commit/bdfaa028be8b562c1ce676574a4cadb9b482d490))

## [1.44.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.43.4...v1.44.0) (2024-10-02)


### Features

* **ecs:** added configuration to use ARM based image with fargate ([a366d34](https://github.com/it-objects/terraform-aws-terra3/commit/a366d34e4843e49969b86c950b1f7e2d03afb72a))

### [1.43.4](https://github.com/it-objects/terraform-aws-terra3/compare/v1.43.3...v1.43.4) (2024-10-02)


### Bug Fixes

* **ssm:** added domain name parameter in main file ([f80bfbc](https://github.com/it-objects/terraform-aws-terra3/commit/f80bfbc5b59f12f78fa87bac7bde1d2cd87cd0fa))

### [1.43.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.43.2...v1.43.3) (2024-09-26)


### Bug Fixes

* **oidc_role:** updated identifier and condition values for iam policy ([700a6bd](https://github.com/it-objects/terraform-aws-terra3/commit/700a6bdfb1c9908c956e9498d3906183fe2102d9))

### [1.43.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.43.1...v1.43.2) (2024-09-25)


### Bug Fixes

* **oidc_role:** updated s3 static website arn ([50915bc](https://github.com/it-objects/terraform-aws-terra3/commit/50915bc4bdd9412e0fcf60bbef223c73d7a9271d))

### [1.43.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.43.0...v1.43.1) (2024-09-25)


### Bug Fixes

* **ssm:** disabled sns alerting smm parameter ([8d5738f](https://github.com/it-objects/terraform-aws-terra3/commit/8d5738f40ca23b30edb73058ec79931083aa02f1))

## [1.43.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.42.1...v1.43.0) (2024-09-25)


### Features

* **oidc_role:** added option to configure the deployment  roles for infra, ecr and s3 static website ([8feccfb](https://github.com/it-objects/terraform-aws-terra3/commit/8feccfb86a0c5c080a7a10b63cb0e0a095b08066))

### [1.42.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.42.0...v1.42.1) (2024-09-25)


### Bug Fixes

* **cloudfront/ssm:** configure to disable creation of CloudFront and SSM parameter resources ([9477c52](https://github.com/it-objects/terraform-aws-terra3/commit/9477c52d61bb9eb52634304f31dc354447396978))

## [1.42.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.8...v1.42.0) (2024-09-25)


### Features

* **oidc:** added option to create OIDC provider ([cc6916a](https://github.com/it-objects/terraform-aws-terra3/commit/cc6916ae537e99068fb19416d5c58f412a888ee3))

### [1.41.8](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.7...v1.41.8) (2024-09-24)


### Bug Fixes

* added parameter to disable creation of resources ([#52](https://github.com/it-objects/terraform-aws-terra3/issues/52)) ([7ea9dcb](https://github.com/it-objects/terraform-aws-terra3/commit/7ea9dcb836caf85b9705751a01209ceda216fc57))

### [1.41.7](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.6...v1.41.7) (2024-09-20)


### Bug Fixes

* **cicd:** revert waiting for steady state after container deployment ([9a24f42](https://github.com/it-objects/terraform-aws-terra3/commit/9a24f4251452e796236fa6997944e9b193c06f34))

### [1.41.6](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.5...v1.41.6) (2024-09-19)


### Bug Fixes

* **cicd:** waits for steady state after container deployment ([48da897](https://github.com/it-objects/terraform-aws-terra3/commit/48da89761754706357e09fce4b8eab053b1f90ce))

### [1.41.5](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.4...v1.41.5) (2024-09-19)


### Bug Fixes

* **outputs:** remove output that returns sensitive data causing warnings during terraform apply ([7a843e9](https://github.com/it-objects/terraform-aws-terra3/commit/7a843e95c50ddd78f389499aa72b8a0cf6c37642))

### [1.41.4](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.3...v1.41.4) (2024-09-09)


### Bug Fixes

* updated ami selector for the NAT instance ([8b48d31](https://github.com/it-objects/terraform-aws-terra3/commit/8b48d3152eea1b509361ec1b9205c7a681c6ce72))

### [1.41.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.2...v1.41.3) (2024-09-09)


### Bug Fixes

* updated default database CA to rds-ca-rsa2048-g1 ([9dc1d41](https://github.com/it-objects/terraform-aws-terra3/commit/9dc1d41536ff7fedad190700b6b6fc39a77492f9))

### [1.41.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.1...v1.41.2) (2024-09-06)


### Bug Fixes

* updated ami name for the NAT instance ([02bd9b2](https://github.com/it-objects/terraform-aws-terra3/commit/02bd9b24b33a288760bd3eea796faf8732570ef3))

### [1.41.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.41.0...v1.41.1) (2024-09-03)


### Bug Fixes

* **cloudfront:** make dependency explicit to S3 log bucket including cloudfront's access privilege to write to it ([3dae43f](https://github.com/it-objects/terraform-aws-terra3/commit/3dae43f944be9c7f7c53030f8b49738b9aa899d0))

## [1.41.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.40.0...v1.41.0) (2024-08-23)


### Features

* updated value of cluster_type reference in app_components to reduce dependency ([12fae54](https://github.com/it-objects/terraform-aws-terra3/commit/12fae547013062524ed367db6cc8acf9f23853c5))

## [1.40.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.39.1...v1.40.0) (2024-08-19)


### Features

* added ignore changes to hibernation_state ssm parameter to avoid drift ([86ccbf6](https://github.com/it-objects/terraform-aws-terra3/commit/86ccbf66d41ca3e47f53a1f732b100188d07ba1c))

### [1.39.1](https://github.com/it-objects/terraform-aws-terra3/compare/v1.39.0...v1.39.1) (2024-08-19)


### Bug Fixes

* removed dependency while using domain name instead of hosted zone ([#51](https://github.com/it-objects/terraform-aws-terra3/issues/51)) ([a29f766](https://github.com/it-objects/terraform-aws-terra3/commit/a29f7667f1a0756e7f26806c80af269b6a7ff75a))

## [1.39.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.38.0...v1.39.0) (2024-07-03)


### Features

* made retention period of ECS log group configurable ([b69175b](https://github.com/it-objects/terraform-aws-terra3/commit/b69175b38b32a3ec2a631306e9c2672b0630a195))

## [1.38.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.37.0...v1.38.0) (2024-06-27)


### Features

* made health check parameters configurable in target group ([1cfd2e9](https://github.com/it-objects/terraform-aws-terra3/commit/1cfd2e9b14f32242405866ed673e8a8de0c94dea))

## [1.37.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.36.0...v1.37.0) (2024-06-20)


### Features

* configure timezone for global scaledown feature ([#49](https://github.com/it-objects/terraform-aws-terra3/issues/49)) ([cdf3a05](https://github.com/it-objects/terraform-aws-terra3/commit/cdf3a0588b86c1fb3ad6a14dfef5008340bd28ce))
* updated nat instance ebs volume type to gp3 ([#50](https://github.com/it-objects/terraform-aws-terra3/issues/50)) ([ce3512e](https://github.com/it-objects/terraform-aws-terra3/commit/ce3512eefb5e583a0cee4b6903fa3bba665e7846))

## [1.36.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.35.0...v1.36.0) (2024-06-11)


### Features

* added disable_vpc_creatio ([#48](https://github.com/it-objects/terraform-aws-terra3/issues/48)) ([77a6fe4](https://github.com/it-objects/terraform-aws-terra3/commit/77a6fe411544a120f4f1ebb388f9b4ce83959c31))
* added disable_vpc_creation ([#47](https://github.com/it-objects/terraform-aws-terra3/issues/47)) ([ee0a81e](https://github.com/it-objects/terraform-aws-terra3/commit/ee0a81eb80cb3d7ed150c3afb3d4fcf012ab35d1))
* updated vpc version in the existing vpc ([1a21b30](https://github.com/it-objects/terraform-aws-terra3/commit/1a21b303db80ad9feca4582da8d542c5b9e5ec59))

## [1.35.0](https://github.com/it-objects/terraform-aws-terra3/compare/v1.34.4...v1.35.0) (2024-05-29)


### Features

* added switch for account level resources ([5e0b0ba](https://github.com/it-objects/terraform-aws-terra3/commit/5e0b0ba49019eada4e16e6042c2122c6f63712ce))

### [1.34.4](https://github.com/it-objects/terraform-aws-terra3/compare/v1.34.3...v1.34.4) (2024-05-23)


### Bug Fixes

* resolve the conflict of name ([b2ba871](https://github.com/it-objects/terraform-aws-terra3/commit/b2ba871684afac972cd049c64c40d74af3b71bd6))

### [1.34.3](https://github.com/it-objects/terraform-aws-terra3/compare/v1.34.2...v1.34.3) (2024-04-24)


### Bug Fixes

* **hibernation:** updated local_file resource to templatefile function ([1495031](https://github.com/it-objects/terraform-aws-terra3/commit/14950315b4ec9c3b24e5bc97720fc1bfe25417c6))

### [1.34.2](https://github.com/it-objects/terraform-aws-terra3/compare/v1.34.1...v1.34.2) (2024-04-23)


### Bug Fixes

* **hibernation:** disabled timestamp for lambda packages ([2df465d](https://github.com/it-objects/terraform-aws-terra3/commit/2df465d7e4ef7011dcecce1dac0eadcb902696ad))

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
