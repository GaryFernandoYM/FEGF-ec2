variable "aws_region" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "key_name" {
  type        = string
  description = "Nombre de la llave SSH creada en AWS"
}

variable "github_token" {
  type = string
}
