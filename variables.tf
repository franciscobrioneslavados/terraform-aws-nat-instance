variable "vpc_id" {
  description = "ID of the VPC where the NAT Instance will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NAT Instance deployment (first one will be used)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets that will use this NAT Instance"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of Route Table IDs that will route traffic through the NAT Instance"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "owner_name" {
  description = "Owner name for resource tagging"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the NAT Instance (e.g., t3.micro, t2.micro)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access. Empty list disables SSH access."
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "Custom AMI ID to use. Null uses Amazon Linux 2."
  type        = string
  default     = null
}

variable "managed_by" {
  description = "ManagedBy tag value"
  type        = string
  default     = "Terraform"
}
