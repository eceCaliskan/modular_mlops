#Set EC2 instance access to the internet and allow SSH
resource "aws_security_group" "allow_ssh" {                                                                                                                
    name        = "allow_ssh"                                                                                                                                
    description = "Allow SSH inbound"                                                                                                                        
                                                                                                                                                             
   ingress {                                                                                                                                                
      from_port   = 22                                                                                                                                       
      to_port     = 22                                                                                                                                       
     protocol    = "tcp"                                                                                                                                    
      cidr_blocks = ["0.0.0.0/0"]                                                                                                                            
   }                                                                                                                                                        
                                                                                                                                                            
   egress {                                                                                                                                                 
     from_port   = 0                                                                                                                                        
     to_port     = 0                                                                                                                                        
     protocol    = "-1"                                                                                                                                     
     cidr_blocks = ["0.0.0.0/0"]                                                                                                                            
   }                                                                                                                                                        
 }   

#Create EC2 instance
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name = "single-instance"
  instance_type = "t3.micro"
  associate_public_ip_address = true    
  monitoring    = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = <<-EOL
    #!/bin/bash -xe
    sudo yum install python3-pip -y
    pip3 install boto3
    python3 -c "import boto3; boto3.client('s3', region_name='us-east-1').download_file('modular-mlops-bucket', 'scripts/train.py','/home/ec2-user/train.py')"
    pip3 install pandas scikit-learn
    sudo touch /var/log/training.log && sudo chmod 666 /var/log/training.log
    python3 /home/ec2-user/train.py >> /var/log/training.log 2>&1
  EOL
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]     
  key_name      = "mlops-key"                                 
  subnet_id     = "subnet-07d5896f8f57e5fab"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}