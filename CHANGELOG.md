# Changelog

All notable changes to this project will be documented in this file.

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
