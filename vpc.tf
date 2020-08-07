provider "aws" {
  region = "ap-south-1"
  profile = "jass"
}


resource "aws_vpc" "myvpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    name = "Teraform_vpc"
  }
}




resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    name = "pub_subnet"
  }
}



resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    name = "pri_subnet"
  }
}



resource "aws_internet_gateway" "vpc_gw1" {
  vpc_id = aws_vpc.myvpc.id 

  tags = {
    name = "Teraform_gw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_gw1.id
  }

  tags = {
    Nam = "hs_routetable"
  }
}
resource "aws_route_table_association" "rt_pub_subnet" {
  subnet_id        = aws_subnet.subnet1.id
  route_table_id   = aws_route_table.rt.id
}

resource "aws_eip" "natlb" {
  vpc = true
}

resource "aws_nat_gateway" "vpc_gw2" {
  allocation_id = aws_eip.natlb.id
  subnet_id = aws_subnet.subnet1.id

  tags = {
    Name = "NAT_gw"
   }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "public"
  }
}


resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "MYSQL-RULE"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "private"
  }
}


resource "aws_instance" "wordpress" {
  ami   = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name = "mykey111222"
  availability_zone = "ap-south-1a"

  tags = {
    name = "wordpress"
  }
}


resource "aws_instance" "MySQL" {
  ami   = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.allow_mysql.id]
  key_name = "mykey111222"
  availability_zone = "ap-south-1b"

  tags = {
    name = "mysql"
  }
}