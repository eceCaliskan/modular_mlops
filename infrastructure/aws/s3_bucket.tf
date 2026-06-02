#source https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/
provider "aws" {
  region = "us-east-1"
}

#Creating the S3 bucket
resource "aws_s3_bucket" "modular_mlops_bucket" {
  bucket = "modular-mlops-bucket"
}

#Trigger S3 bucket to send notification when a new file added
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.modular_mlops_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
    filter_suffix       = ".log"
  }
}

