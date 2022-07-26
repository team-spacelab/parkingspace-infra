terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
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
