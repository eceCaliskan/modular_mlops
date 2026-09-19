#This file is responsible for setting permissions in AWS using Terraform
#
#This file is a part of OUT2 A reproducible open-source MLOps pipeline modules implemented with IaC approach.
#
#Main resource that is used to create all of the permission below is hashicorp documentation about iam
#https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest
#

#Creating lambda lambda_exec_role
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

#Creating ec2 ec2_exec_role
resource "aws_iam_role" "ec2_exec" {
  name = "ec2_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#Giving EC2 instances necessary permissions to communicate with S3 bucket and Lambda Functions
resource "aws_iam_role_policy" "ec2_exec" {
    name = "ec2_exec"
    role = aws_iam_role.ec2_exec.id

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject",
                      "s3:PutObject",
                      "s3:ListBucket",                                                                                                                                                  
                      "s3:DeleteObject",  
                      "ssm:GetParameter",
                      "s3-object-lambda:Get*",
                      "s3-object-lambda:List*",
                      "ec2:DescribeInstances",
                      "ec2:StopInstances"
                    ]
          Resource = "*"
        }
      ]
    })
  }


  resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.ec2_exec.name
  }

#Giving lambda function necessary permissions to communicate with S3 bucket and EC2 instance
 resource "aws_iam_role_policy" "lambda_ec2_start" {
    name = "lambda_ec2_start"
    role = aws_iam_role.lambda_exec.id

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["ec2:StartInstances", 
                      "ec2:StopInstances", 
                      "ec2:DescribeInstances", 
                      "ssm:PutParameter", 
                      "ssm:GetParameter",
                      "ssm:SendCommand"
                     ]
          Resource = "*"
        }
      ]
    })
  }

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {                                                                                                        
  role       = aws_iam_role.ec2_exec.name                                                                                                                    
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"                                                                                        
}                                                                                                                                                            
          
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}