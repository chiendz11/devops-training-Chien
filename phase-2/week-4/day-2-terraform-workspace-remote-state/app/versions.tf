terraform {
  required_version = ">= 1.6"

  backend "s3" {}

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

