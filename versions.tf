terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.4.3, < 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.4, < 5.0.0"
    }
  }
}
