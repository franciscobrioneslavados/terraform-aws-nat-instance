locals {
  global_tags = {
    "Environment" = var.environment
    "ManagedBy"   = var.managed_by
    "OwnerName"   = var.owner_name
    "ProjectName" = var.project_name
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# AMI de NAT Instance (Amazon Linux 2)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Security Group para la NAT Instance
resource "aws_security_group" "nat_instance" {
  name        = "nat-instance-sg"
  description = "Security group para NAT Instance"
  vpc_id      = var.vpc_id

  # SSH access desde tu IP (opcional para administración)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr # Cambia esto por tu IP específica
  }

  # ICMP (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # Tráfico de las subnets privadas hacia la NAT
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    description = "Allow TCP from private subnets only"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Salida a internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-nat-instance-sg"
  })
}

# Generar clave SSH automáticamente
resource "tls_private_key" "tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.environment}-${var.project_name}-key"
  public_key = tls_private_key.tls_private_key.public_key_openssh

  tags = {
    Name = "${var.project_name}-keypair"
  }
}

# Guardar la clave privada localmente
resource "local_file" "private_key" {
  content         = tls_private_key.tls_private_key.private_key_pem
  filename        = "${path.module}/${aws_key_pair.key_pair.key_name}.pem"
  file_permission = "0400"
}


# NAT Instance
resource "aws_instance" "nat_instance" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.nat_instance.id]
  associate_public_ip_address = true
  source_dest_check           = false # Importante para NAT
  user_data                   = <<-EOT
    #!/bin/bash
    # Configuración automática de NAT Instance
    
    # Actualizar sistema
    yum update -y
    
    # Habilitar IP forwarding
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    sysctl -p
    
    # Instalar iptables
    yum install -y iptables-services
    
    # Configurar NAT
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
    
    # Guardar reglas persistentes
    iptables-save > /etc/sysconfig/iptables
    
    # Habilitar y iniciar iptables
    systemctl enable iptables
    systemctl start iptables
    
    # Instalar herramientas de diagnóstico
    yum install -y tcpdump curl wget
    
    echo "NAT Instance configurada exitosamente"
  EOT

  root_block_device {
    volume_type           = "gp3"
    delete_on_termination = true
  }

  key_name = aws_key_pair.key_pair.key_name

  tags = merge(local.global_tags, {
    Name = "ec2-${var.environment}-${var.project_name}"
  })

  depends_on = [aws_key_pair.key_pair]
}


# Elastic IP para la NAT Instance
resource "aws_eip" "eip_nat" {
  domain = "vpc"

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-eip"
  })
}

resource "aws_eip_association" "nat_eip_assoc" {
  allocation_id        = aws_eip.eip_nat.id
  network_interface_id = aws_instance.nat_instance.primary_network_interface_id
}

resource "aws_route" "private_nat_instance" {
  route_table_id         = var.route_table_id
  destination_cidr_block = "0.0.0.0/0"

  network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  # alternativa, si prefieres referenciar la instancia directamente:
  # instance_id = aws_instance.nat.id
  # instance_id = aws_instance.nat.id

  depends_on = [aws_instance.nat_instance]

  lifecycle {
    create_before_destroy = true
  }
}
