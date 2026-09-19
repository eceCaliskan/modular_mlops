#This file is responsible for setting up the S3 bucket in AWS vendor using Terraform.
#
#This file is a part of OUT2 A reproducible open-source MLOps pipeline modules implemented with IaC approach.
#
#Main resources used as follows
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/
#https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission
#https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/master/examples/notification/main.tf

#source https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/
provider "aws" {
  region = "us-east-1"
}

#Allow permission for S3 bucket to invoke lambda
#Source https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest
#Creating the S3 bucket
resource "aws_s3_bucket" "modular_mlops_bucket" {
  bucket = "modular-mlops-bucket"
}

#Allow permission for S3 bucket to invoke lambda
#Source https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission
resource "aws_lambda_permission" "allow_s3" {                                                                                                                                
 statement_id  = "AllowS3Invoke"                                                                                                                                            
 action        = "lambda:InvokeFunction"                                                                                                                                    
 function_name = aws_lambda_function.my_function.function_name                                                                                                              
 principal     = "s3.amazonaws.com"                                                                                                                                         
 source_arn    = aws_s3_bucket.modular_mlops_bucket.arn                                                                                                                     
}  

#Trigger S3 bucket to send notification when a new file added
#Source https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/master/examples/notification/main.tf
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.modular_mlops_bucket.id
  depends_on = [aws_lambda_permission.allow_s3]
  lambda_function {
    lambda_function_arn = aws_lambda_function.my_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "dataset/"
    filter_suffix       = ".csv"
  }
}

#Enabling versioning for S3 buckets
#Source https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.modular_mlops_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}