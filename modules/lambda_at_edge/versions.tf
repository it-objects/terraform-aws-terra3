terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">=4.53.0"
      configuration_aliases = [aws.useast1]
    }
  }
}
