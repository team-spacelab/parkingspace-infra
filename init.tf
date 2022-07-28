terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }

    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

variable "profile" {
  type = string 
}

provider "aws" {
  alias = "n_verginia"
  region = "us-east-1"
  profile = var.profile
}

provider "aws" {
  region = "ap-northeast-2"
  profile = var.profile
}

provider "local" {}

provider "tls" {}
