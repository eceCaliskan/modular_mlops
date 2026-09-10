#This file is responsible for setting up the lambda function using Terraform
#The resource is used to define this component is hashicorp documentation about lambda functions
#https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest

#Setting up the lambda function
resource "aws_lambda_function" "my_function" {
    filename         = "${path.module}/function.zip"
    function_name    = "my-function"
    role             = aws_iam_role.lambda_exec.arn
    handler          = "function.lambda_handler"
    runtime          = "python3.12"
    source_code_hash = filebase64sha256("${path.module}/function.zip")
    timeout          = 300
  }