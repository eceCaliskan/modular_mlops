#source https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/
#Setting up the lambda function
resource "aws_lambda_function" "trigger_ec2" {
    filename         = "${path.module}/function.zip"
    function_name    = "my-function"
    role             = aws_iam_role.lambda_exec.arn
    handler          = "function.lambda_handler"
    runtime          = "python3.12"
    source_code_hash = filebase64sha256("${path.module}/function.zip")
  }