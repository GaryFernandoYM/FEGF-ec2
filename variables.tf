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

variable "key_name_prefix" {
  description = "Prefijo con el que Terraform nombrará la llave SSH"
  type        = string
  default     = "mi-key-fegf-"
}
