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
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]     
  subnet_id     = "subnet-07d5896f8f57e5fab"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}