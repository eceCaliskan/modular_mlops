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

#Set EC2 instance access to the internet and allow tools to be on dedicated ports
 resource "aws_security_group" "allow_access" {                                                                                                                
    name        = "allow_access"                                                                                                                                
    description = "Allow SSH inbound"                                                                                                                        
    ingress {                                                                                                                                                
      from_port   = 8080                                                                                                                                       
      to_port     = 8080                                                                                                                                       
     protocol    = "tcp"                                                                                                                                    
      cidr_blocks = ["0.0.0.0/0"]                                                                                                                            
   }                
     ingress {                                                                                                                                                
      from_port   = 3100                                                                                                                                       
      to_port     = 3100                                                                                                                                       
     protocol    = "tcp"                                                                                                                                    
      cidr_blocks = ["0.0.0.0/0"]                                                                                                                            
   }                 
    ingress {                                                                                                                                                
      from_port   = 8000                                                                                                                                       
      to_port     = 8000                                                                                                                                       
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

#Create EC2 instance for training
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name = "Training"
  instance_type = "t3.micro"
  associate_public_ip_address = true    
  monitoring    = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = templatefile("${path.module}/training-user-data.sh", {
    loki_url = "http://${module.ec2_instance2.private_ip}:3100/loki/api/v1/push"
  })
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]     
  key_name      = "mlops-key"                                 
  subnet_id     = "subnet-07d5896f8f57e5fab"
  tags = {Purpose = "Training"}
}

#Create EC2 instance for registry, monitoring and deployment
module "ec2_instance2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name = "Monitoring_Deployment_Registry"
  tags = {Purpose = "Monitoring_Deployment_Registry"}
  instance_type = "t3.small"
  associate_public_ip_address = true    
  monitoring    = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = file("${path.module}/user-data.sh")   
  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.allow_access.id, aws_security_group.allow_ssh.id]     
  key_name      = "mlops-key"                                 
  subnet_id     = "subnet-07d5896f8f57e5fab"
}

#Adding loki url as an ssm parameter to be used by lambda function
resource "aws_ssm_parameter" "loki_url" {
    name  = "/ml/loki_url"
    type  = "String"
    value = "http://${module.ec2_instance2.public_ip}:3100/loki/api/v1/push"
}