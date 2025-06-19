# Proveedor AWS
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Obtener VPC por defecto
data "aws_vpc" "default" {}

# 🔐 Grupo de seguridad para EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_s3_sg_fegf"
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
    description = "Todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_ec2_s3_fegf"
  }
}

# 🎯 IAM Role para que EC2 acceda a S3
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_role_fegf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Adjuntar política de solo lectura a S3
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Crear el perfil de instancia EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile_fegf"
  role = aws_iam_role.ec2_s3_role.name
}

# 🚀 Instancia EC2 Ubuntu 20.04 (free tier)
resource "aws_instance" "ec2_fegf" {
  ami = "ami-053b0d53c279acc90"  # Ubuntu Server 20.04 LTS (us-east-1)
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "instancia-fegf"
  }


}
  output "public_ip" {
  value = aws_instance.ec2_fegf.public_ip
}
