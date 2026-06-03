 terraform {
    required_version = ">= 1.0"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
  }

# import {                                                                                                                                                                      
#    to = module.infrastructure.aws_iam_role.lambda_exec                                                                                                                                          
#    id = "lambda_exec_role"                                                                                                                                                     
# }     

#Define AWS provider
  provider "aws" {
    region = "us-east-1"
  }

#Pointing to AWS folder
  module "infrastructure" {
    source = "./infrastructure/aws"
  }