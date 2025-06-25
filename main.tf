provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Obtener VPC por defecto
data "aws_vpc" "default" {}

# 🔐 Crear un nuevo Security Group (nombre dinámico)
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2_s3_sg_fegf_"
  description = "Permitir SSH, HTTP y HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH desde cualquier lugar"
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
    description = "Todo el tráfico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_s3_fegf"
  }
}

# ✅ Reutilizar IAM Role existente
data "aws_iam_role" "existing_role" {
  name = "ec2_s3_role_fegf"
}

# ✅ Reutilizar IAM Instance Profile existente
data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_profile_fegf"
}

# 🚀 Instancia EC2 con todo configurado
resource "aws_instance" "ec2_fegf" {
  ami                         = "ami-053b0d53c279acc90" # Ubuntu Server 20.04 LTS (us-east-1)
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.existing_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "instancia-fegf"
  }
}

# 🌐 Output con la IP pública
output "public_ip" {
  value = aws_instance.ec2_fegf.public_ip
}
