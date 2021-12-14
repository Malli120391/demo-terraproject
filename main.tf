provider "aws" {
  region = "ap-south-1"
  access_key = "AKIAXJQW2XIOZY2XADSM"
  secret_key = "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"
}

   variable "vpc_cidr_block" {}
   variable "subnet_cidr_block" {}
  variable "avail_zone" {}
  variable "env_prefix" {}
  variable "my_ip" {}
  variable "instance_type" {}
  variable "public_key_location" {}
resource  "aws_vpc"  "myapp-vpc" {

   cidr_block = var.vpc_cidr_block
   tags = {
       Name = "${var.env_prefix}-vpc"
  }

}
resource "aws_subnet" "myapp_subnet-1" {

     vpc_id = aws_vpc.myapp-vpc.id
     
     cidr_block = var.subnet_cidr_block
     availability_zone = var.avail_zone
     tags = {
         Name = "${var.env_prefix}-subnet-1"
  }
  
}
#custiom rtb creation
/*resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
         Name = "${var.env_prefix}-rtb"
  }

}*/
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
         Name = "${var.env_prefix}-igw"
  }
}
#default rtb creation
resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc. default_route_table_id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
         Name = "${var.env_prefix}-main-rtb"
  }
}
/*resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp_subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id

  
}*/
#default security group creation
resource "aws_default_security_groups" "default-sg" {
  #name        = "myapp-sg"
  #description = "Security group creation for vpc"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description      = "incoming ruls from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "incoming ruls from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
  
}
#custom security group creation
/*resource "aws_security_groups" "myapp-sg" {
  name        = "myapp-sg"
  description = "Security group creation for vpc"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description      = "incoming ruls from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "incoming ruls from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
  
}*/


 data "aws_ami" "latast-amazon-linux-image"{
   most_recent = true
   owners = ["137112412989"]
   filter {
     name = "name"
     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
   }
   filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
 }
 output "aws_ami_id" {
   value = data.aws_ami.latast-amazon-linux-image.id
   
 }
 output "ec2_public_ip" {
   value = aws_instance.myapp-server.public_ip
   
 }
 resource "aws_key_pair" "ssh-key" {
   key_name   = "server-key"
  public_key  = file(var.public_key_location)

 }
 resource "aws_instance" "myapp-server" {
   ami = data.aws_ami.latast-amazon-linux-image.id
   instance_type = var.instance_type

   subnet_id = aws_subnet.myapp_subnet-1.id
   vpc_security_group_ids = [aws_default_security_groups.default-sg.id]
   availability_zone = var.avail_zone
   associate_public_ip_address = true
   #key_name = "redrhel"
   key_name = var.aws_key_pair.ssh-key.key_name

   /*user_data = <<EOF

            #!/bin/bash
            sudo yum update -y && sudo yum install docker -y
            sudo systemctl start docker
            sudo usermod -aG docker ec2-user
            docker run -p 8080:80 nginx
 
     EOF*/

    # user_data = file("entry-script.sh")
   
   connection {
      type     = "ssh"
      user     = "ec2-user"
      #password = var.root_password
      host     = self.public_ip
      private_key = file(var.private_key_location)
  }

     provisioner "file" {
       source = "entry-script.sh"
       destination = "/home/ec2-user/entry-script-on-ec2.sh"
     
     }

     /*provisioner "file" {
       source = "entry-script.sh"
       destination = "/home/ec2-user/entry-script-on-ec2.sh"

       connection {
      type     = "ssh"
      user     = "ec2-user"
      #password = var.root_password
      host     = self.someotherserver.public_ip
      private_key = file(var.private_key_location)
  }
     
     }*/
     provisioner "remote-exec" {

       script = file("entry-script-on-ec2.sh")

       #script = file("entry-script.sh")

       /*inline = [
         "export ENV=dev",
         "mkdir newdir"
       ]*/
       
     }

     provisioner "local-exec" {

       command = "echo ${self.public_ip} > output.txt"
     
     }

   tags = {
     Name = "${var.env_prefix}-server"
   }
 }
