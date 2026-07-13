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
          