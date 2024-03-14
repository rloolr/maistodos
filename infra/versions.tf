provider "aws" {
  region  = var.region
  profile = "s2w"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  # backend "s3" {
  #   bucket = "task-mais-todos"
  #   region = "us-east-1"
  #   key = "tfstate-dir/terraform.tfstate"
  #   encrypt = true
  # }
}

