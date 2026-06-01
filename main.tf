 terraform {
    required_version = ">= 1.0"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  }

#Define AWS provider
  provider "aws" {
    region = "us-east-1"
  }

#Pointing to AWS folder
  module "infrastructure" {
    source = "./infrastructure/aws"
  }