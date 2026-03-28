variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for resource deployment"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks para las subnets privadas"
  type        = list(string)
}

variable "route_table_id" {
  description = "ID de la tabla de rutas a actualizar"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto para tagging"
  type        = string
}

variable "environment" {
  description = "aws environment"
  type        = string
}

variable "managed_by" {
  description = "value for the ManagedBy tag"
  type        = string
  default     = "Terraform"
}

variable "owner_name" {
  description = "value for the Owner tag"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia para NGINX"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block for SSH access"
  type        = list(string)
}
