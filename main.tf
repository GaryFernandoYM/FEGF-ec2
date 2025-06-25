provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# VPC existente
data "aws_vpc" "default" {}

data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["ec2_s3_sg_fegf"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# ✅ Reutilizar Role existente (no crear)
data "aws_iam_role" "existing_role" {
  name = "ec2_s3_role_fegf"
}

# ✅ Reutilizar Instance Profile existente
data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_profile_fegf"
}

# 🚀 Instancia EC2 con recursos reutilizados
resource "aws_instance" "ec2_fegf" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "instancia-fegf"
  }
}

# 🌐 Output de IP pública
output "public_ip" {
  value = aws_instance.ec2_fegf.public_ip
}
