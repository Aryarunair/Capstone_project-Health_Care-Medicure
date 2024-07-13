provider "aws" {
  region = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "K8s VPC"
  }
}

# Create Internet Gateway 
resource "aws_internet_gateway" "k8s_gw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "K8s Gateway"
  }
}

# Create Route Table
resource "aws_route_table" "k8s_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_gw.id
  }

  tags = {
    Name = "K8s Route Table"
  }
}

# Create Subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "K8s Subnet"
  }
}

# Create Security Group for K8s Master
resource "aws_security_group" "k8s_master_sg" {
  name   = "K8s Master Security Group"
  vpc_id = aws_vpc.k8s_vpc.id
ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }
}

# Create Security Group for K8s Worker
resource "aws_security_group" "k8s_worker_sg" {
  name   = "K8s Worker Security Group" 
  vpc_id = aws_vpc.k8s_vpc.id
ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }
}
 

# Create EC2 Instance for K8s Master
resource "aws_instance" "k8s_master" {
  ami           = "ami-0c2af51e265bd5e0e" 
  instance_type = "t2.micro"
  key_name      = "healthcare.pem"

  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_master_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "K8s Master"
  }
}

# Create EC2 Instance for K8s Worker  
resource "aws_instance" "k8s_worker" {
  ami           = "ami-0c2af51e265bd5e0e"
  instance_type = "t2.micro" 
  key_name      = "healthcare.pem"

  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_worker_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "K8s Worker"
  }
}
