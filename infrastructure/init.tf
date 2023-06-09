terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "dontgiveafish"
}

terraform {
  backend "remote" {
    organization = "dontgiveafish"

    workspaces {
      name = "phpdaily_"
    }
  }
}
