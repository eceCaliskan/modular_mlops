#Installing the required provider sources 
# Source https://developer.hashicorp.com/terraform/language/block/provider
terraform {
    required_version = ">= 1.0"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
      }
      google = {
        source  = "hashicorp/google"
        version = "~> 6.0"
      }
    }
}

#Define AWS provider
provider "aws" {
  region = "us-east-1"
}

#Define GCP provider
provider "google" {
  project = "project-8fba7723-3f35-48db-ae1" 
  region  = "us-central1"
}

#Pointing to AWS folder
module "infrastructure" {
  source = "./infrastructure/aws"
}

#Pointing to GCP folder
module "infrastructure2" {
  source = "./infrastructure/gcp"
}

