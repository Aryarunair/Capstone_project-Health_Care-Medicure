provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  id = "vpc-0a19c641974f61822"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
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

resource "aws_instance" "k8s_master" {
  ami           = "ami-0b2f6494ff0b07a0e" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t2.micro"
  key_name      = "healthcare.pem"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.k8s_sg.name]

  associate_public_ip_address = true

  tags = {
    Name = "K8sMaster"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -aG docker ec2-user
              curl -sfL https://get.k3s.io | sh -
              EOF
}

resource "aws_eip" "k8s_master_eip" {
  instance = aws_instance.k8s_master.id
}

resource "null_resource" "retrieve_k3s_token" {
  provisioner "remote-exec" {
    inline = [
      "sleep 60", # Wait for the master node to initialize
      "scp -o StrictHostKeyChecking=no -i /path/to/healthcare.pem ec2-user@${aws_instance.k8s_master.public_ip}:/var/lib/rancher/k3s/server/node-token ./node-token"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/path/to/healthcare.pem")
      host        = aws_instance.k8s_master.public_ip
    }
  }
}

resource "aws_instance" "k8s_worker" {
  ami           = "ami-0c2af51e265bd5e0e"
  instance_type = "t2.micro"
  key_name      = "healthcare.pem"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.k8s_sg.name]

  associate_public_ip_address = true

  tags = {
    Name = "K8sWorker"
  }

  depends_on = [null_resource.retrieve_k3s_token]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -aG docker ec2-user
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k8s_master.private_ip}:6443 K3S_TOKEN=$(cat ./node-token) sh -
              EOF
}
