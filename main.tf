provider "aws" {
  region = var.aws_region
}

# Data source para pegar a VPC existente pelo nome
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name] # Nome da VPC que você quer referenciar
  }
}

# Data source para pegar uma sub-rede associada à VPC
data "aws_subnet" "existing" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Name"
    values = ["dev-public-subnet-1"] # Substitua pelo nome ou tag da sub-rede
  }
  # Opcional: Adicione mais filtros se necessário, como tags específicas
}

# IAM Role para a EC2
resource "aws_iam_role" "ec2_role" {
  name = var.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy Attachment para permitir acesso necessário
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Security Group para a EC2
resource "aws_security_group" "ec2_sg" {
  name        = var.security_group_name
  description = "Allow inbound traffic for Zipkin"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description      = "Allow HTTP"
    from_port        = 9411
    to_port          = 9411
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   # Regra para tráfego SSH
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Recomenda-se restringir ao seu IP público
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elastic IP
resource "aws_eip" "zipkin_ip" {
  instance = aws_instance.zipkin.id
}

# Instância EC2
resource "aws_instance" "zipkin" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.existing.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "zipkin-instance-${var.environment}"
  }

 user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
              cat > /docker-compose.yml <<-EOL
              version: "3"
              services:
                zipkin:
                  image: openzipkin/zipkin
                  ports:
                    - "9411:9411"
              EOL
              docker-compose -f /docker-compose.yml up -d
              EOF
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-zipkin-instance-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}