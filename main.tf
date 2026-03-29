locals {
  global_tags = {
    "Environment" = var.environment
    "ManagedBy"   = var.managed_by
    "OwnerName"   = var.owner_name
    "ProjectName" = var.project_name
  }
}

data "aws_ami" "amazon_linux_2" {
  count       = var.ami_id != null ? 0 : 1
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

resource "aws_security_group" "nat_instance" {
  name        = "${var.environment}-${var.project_name}-nat-sg"
  description = "Security group for NAT Instance"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "SSH access from allowed CIDRs"
    }
  }

  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "ICMP (ping) from allowed CIDRs"
    }
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    description = "TCP from private subnets"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = var.private_subnet_cidrs
    description = "UDP from private subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-nat-instance-sg"
  })
}



resource "aws_instance" "nat_instance" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2[0].id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.nat_instance.id]
  associate_public_ip_address = true
  source_dest_check           = false
  key_name                    = var.key_name

  user_data = <<-EOT
    #!/bin/bash
    set -e

    dnf update -y

    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    sysctl -p

    dnf install -y iptables-services

    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT

    iptables-save > /etc/sysconfig/iptables

    systemctl enable iptables
    systemctl start iptables

    dnf install -y tcpdump curl wget

    echo "NAT Instance configured successfully"
  EOT

  root_block_device {
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.global_tags, {
    Name = "ec2-${var.environment}-${var.project_name}"
  })

}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-eip"
  })
}

resource "aws_eip_association" "nat_eip" {
  allocation_id        = aws_eip.nat.id
  network_interface_id = aws_instance.nat_instance.primary_network_interface_id
}

resource "aws_route" "nat_instance" {
  count                  = length(var.route_table_ids)
  route_table_id         = var.route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id

  depends_on = [aws_instance.nat_instance]

  lifecycle {
    create_before_destroy = true
  }
}
