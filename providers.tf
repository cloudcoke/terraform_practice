terraform {
  cloud {
    organization = "cloudcoke"

    workspaces {
      name = "wallet"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1"
    }
  }
}