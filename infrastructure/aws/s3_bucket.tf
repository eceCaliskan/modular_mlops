#source https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/
provider "aws" {
  region = "us-east-1"
}

#Creating the S3 bucket
resource "aws_s3_bucket" "modular_mlops_bucket" {
  bucket = "modular-mlops-bucket"
}

#Allow permission for S3 bucket to invoke lambda
resource "aws_lambda_permission" "allow_s3" {                                                                                                                                
 statement_id  = "AllowS3Invoke"                                                                                                                                            
 action        = "lambda:InvokeFunction"                                                                                                                                    
 function_name = aws_lambda_function.my_function.function_name                                                                                                              
 principal     = "s3.amazonaws.com"                                                                                                                                         
 source_arn    = aws_s3_bucket.modular_mlops_bucket.arn                                                                                                                     
}  

#Trigger S3 bucket to send notification when a new file added
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

