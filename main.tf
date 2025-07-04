provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

data "aws_vpc" "default" {}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2_s3_sg_fegf_"   # evita duplicados
  description = "Permit SSH (22), HTTP (80) y HTTPS (443)"
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
    description = "all-egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  description = "Flask App"
  from_port   = 5000
  to_port     = 5000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = { Name = "sg_ec2_s3_fegf" }
}

# — intenta reutilizar si ya existe —
data "aws_iam_role" "existing_role" {
  name = "ec2_s3_role_fegf"
}

resource "aws_iam_role" "role" {
  count      = length(data.aws_iam_role.existing_role.*.id) == 0 ? 1 : 0
  name       = "ec2_s3_role_fegf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  count      = length(data.aws_iam_role.existing_role.*.id) == 0 ? 1 : 0
  role       = aws_iam_role.role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

data "aws_iam_instance_profile" "existing" {
  name = "ec2_profile_fegf"
}

resource "aws_iam_instance_profile" "profile" {
  count = length(data.aws_iam_instance_profile.existing.*.id) == 0 ? 1 : 0
  name  = "ec2_profile_fegf"
  role  = try(aws_iam_role.role[0].name, data.aws_iam_role.existing_role.name)
}

locals {
  instance_profile_name = try(
    aws_iam_instance_profile.profile[0].name,
    data.aws_iam_instance_profile.existing.name
  )
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_instance" "ec2_fegf" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.micro"
  key_name               = "FEGF"  # Reemplaza por tu clave .pem ya creada en AWS
  iam_instance_profile   = local.instance_profile_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true


  tags = { Name = "instancia-fegf" }
}


output "public_ip" {
  value       = aws_instance.ec2_fegf.public_ip
  description = "IP pública de la instancia"
}
