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

variable "os_type" {
  description = "Operating System type (amazon-linux-2 or ubuntu)"
  type        = string
  default     = "amazon-linux-2"
  validation {
    condition     = contains(["amazon-linux-2", "ubuntu"], var.os_type)
    error_message = "os_type must be either 'amazon-linux-2' or 'ubuntu'."
  }
}

variable "user_data_al2" {
  description = "User data for Amazon Linux 2 NAT Instance"
  type        = string
  default     = <<-EOT
    #!/bin/bash
    set -e

    # Usar yum en lugar de dnf para máxima compatibilidad
    yum update -y

    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    sysctl -p

    yum install -y iptables-services

    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT

    # Guardar reglas para persistencia
    iptables-save > /etc/sysconfig/iptables

    systemctl enable iptables
    systemctl start iptables

    yum install -y tcpdump curl wget
    
    echo "NAT Instance configured successfully"
  EOT
}

variable "user_data_ubuntu" {
  description = "User data for Ubuntu NAT Instance"
  type        = string
  default     = <<-EOT
     #!/bin/bash
     set -e
   
     # Actualizar repositorios
     apt-get update -y
     
     # Habilitar forwarding en el kernel
     echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
     sysctl -p
   
     # Instalar iptables-persistent sin que pida confirmación manual
     # Esto es vital para Ubuntu durante el boot
     export DEBIAN_FRONTEND=noninteractive
     apt-get install -y iptables-persistent tcpdump curl wget
   
     # Configurar reglas de NAT
     iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
     iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
   
     # Guardar las reglas para que persistan tras reinicios
     netfilter-persistent save
   
     echo "NAT Instance (Ubuntu) configured successfully"
   EOT
}