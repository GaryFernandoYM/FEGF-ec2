provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Obtener VPC por defecto
data "aws_vpc" "default" {}

# Buscar Security Group existente
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["ec2_s3_sg_fegf"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  # Si no existe, Terraform lo ignorará
  depends_on = [data.aws_vpc.default]
  lifecycle {
    ignore_errors = true
  }
}

# Crear SG solo si no existe
resource "aws_security_group" "ec2_sg" {
  count       = length(try(data.aws_security_group.existing_sg.id, "")) == 0 ? 1 : 0
  name        = "ec2_s3_sg_fegf"
  description = "Permitir SSH, HTTP y HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "sg_ec2_s3_fegf"
  }
}

# Reutilizar Role e Instance Profile existentes
data "aws_iam_role" "existing_role" {
  name = "ec2_s3_role_fegf"
}

data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_profile_fegf"
}

# Crear instancia EC2
resource "aws_instance" "ec2_fegf" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    length(try(data.aws_security_group.existing_sg.id, "")) > 0
      ? data.aws_security_group.existing_sg.id
      : aws_security_group.ec2_sg[0].id
  ]

  tags = {
    Name = "instancia-fegf"
  }
}

# Salida: IP pública
output "public_ip" {
  value = aws_instance.ec2_fegf.public_ip
}
