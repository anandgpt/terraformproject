provider "aws"{
    region ="ap-south-1"
    access_key = "AKIAZASIIQE7ORNGQMWA"
    secret_key = "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"
}
/*
resource "<provider>_<resource_type>" "name" {
  config option....connection {
    key="values"
    key2="another name"
  }
}*/
resource "aws_vpc" "first_VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "production"
  }
}

resource "aws_subnet" "Subnet-1" {
  vpc_id     = aws_vpc.first_VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Prod-subnet"
  }
}