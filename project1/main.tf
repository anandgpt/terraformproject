
provider "aws"{
    region ="ap-south-1"
    access_key = "AKIAZASIIQE7ORNGQMWA"
    secret_key = "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"
}

#create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
    tags={
        Name="production"
    }
}

#create internet gateway

resource "aws_internet_gateway" "my-gw" {
  vpc_id = aws_vpc.prod-vpc.id

}

#create custom route table

resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.prod-vpc.id

  route{
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.my-gw.id
    }
    route{
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.my-gw.id
    }
    tags = {
      Name = "Prod"
      }

}

#create subnet
resource "aws_subnet" "prod-subnet" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "prod-subnet"
  }
}

#associate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod_route_table.id
}

#create security group to allow port 22, 80,443

resource "aws_security_group" "allow-web" {
  name        = "allow_web-traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress{
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress{
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress{
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "allow_web"
  }
}

# network interface

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]
}

#Elastic IP
resource "aws_eip" "one" {
    vpc      = true
    network_interface = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.my-gw]
 
}

resource "aws_instance" "web-server-instance" {
  ami           = "ami-04bde106886a53080"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "main-key"
  network_interface {
    device_index=0
    network_interface_id=aws_network_interface.web-server-nic.id
  }
  


//apache installation
user_data= <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo bash -c 'echo Kya haal hai bhaskar .. mustubation kia ki nahi > /var/www/html/index.html'
    EOF
tags = {
    Name = "ubuntu-server"
  }
}