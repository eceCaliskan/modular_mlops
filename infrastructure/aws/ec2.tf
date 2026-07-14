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

resource "aws_security_group" "allow_mlflow" {                                                                                                                
    name        = "allow_mlflow"                                                                                                                                
    description = "Allow SSH inbound"                                                                                                                        
                                                                                                                                                             
   ingress {                                                                                                                                                
      from_port   = 8080                                                                                                                                       
      to_port     = 8080                                                                                                                                       
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
 resource "aws_security_group" "allow_fastapi" {                                                                                                                
    name        = "allow_fastapi"                                                                                                                                
    description = "Allow SSH inbound"                                                                                                                        
                                                                                                                                                             
   ingress {                                                                                                                                                
      from_port   = 8000                                                                                                                                       
      to_port     = 8000                                                                                                                                       
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
 resource "aws_security_group" "allow_grafana" {                                                                                                                
    name        = "allow_grafana"                                                                                                                                
    description = "Allow SSH inbound"                                                                                                                        

     ingress {                                                                                                                                                
      from_port   = 3100                                                                                                                                       
      to_port     = 3100                                                                                                                                       
     protocol    = "tcp"                                                                                                                                    
      cidr_blocks = ["0.0.0.0/0"]                                                                                                                            
   }                                                                                                                                                
   ingress {                                                                                                                                                
      from_port   = 3000                                                                                                                                       
      to_port     = 3000                                                                                                                                       
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
  name = "Training"
  instance_type = "t3.micro"
  associate_public_ip_address = true    
  monitoring    = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = <<-EOL
    #!/bin/bash -xe
    sudo yum install python3-pip -y
    sudo pip3 install --ignore-installed boto3 pandas scikit-learn mlflow
    python3 -c "import boto3; boto3.client('s3', region_name='us-east-1').download_file('modular-mlops-bucket', 'scripts/train.py','/home/ec2-user/train.py')"
    sudo touch /var/log/training.log && sudo chmod 666 /var/log/training.log
    python3 /home/ec2-user/train.py >> /var/log/training.log 2>&1
  EOL
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]     
  key_name      = "mlops-key"                                 
  subnet_id     = "subnet-07d5896f8f57e5fab"
  tags = {Purpose = "Training"}
}

#Create EC2 instance
module "ec2_instance2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name = "Monitoring"
  tags = {Purpose = "Monitoring"}
  instance_type = "t3.small"
  associate_public_ip_address = true    
  monitoring    = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = file("${path.module}/user-data.sh")   
  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.allow_mlflow.id, aws_security_group.allow_ssh.id, aws_security_group.allow_fastapi.id, aws_security_group.allow_grafana.id]     
  key_name      = "mlops-key"                                 
  subnet_id     = "subnet-07d5896f8f57e5fab"
}