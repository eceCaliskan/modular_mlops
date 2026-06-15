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

#Pointing to AWS folder
  module "infrastructure" {
    source = "./infrastructure/aws"
  }

  #Pointing to GCP folder
  module "infrastructure2" {
    source = "./infrastructure/gcp"
  }

   provider "google" {
    project = "project-a280d5fe-bdeb-4fbe-aa0" ## CHANGE WITH THE ACTUAL PROJECT ID
    region  = "us-central1"
  }