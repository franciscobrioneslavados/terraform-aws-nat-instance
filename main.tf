locals {
  global_tags = {
    "Environment" = var.environment
    "ManagedBy"   = var.managed_by
    "OwnerName"   = var.owner_name
    "ProjectName" = var.project_name
  }
}

data "aws_ami" "amazon_linux_2" {
  count       = (var.ami_id == null && var.os_type == "amazon-linux-2") ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.cpu_architecture == "arm64" ? "amzn2-ami-hvm-*-arm64-gp2" : "amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "architecture"
    values = [var.cpu_architecture]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "al2023" {
  count       = (var.ami_id == null && var.os_type == "al2023") ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.cpu_architecture == "arm64" ? "al2023-ami-kernel-*-arm64" : "al2023-ami-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = [var.cpu_architecture]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu" {
  count       = (var.ami_id == null && var.os_type == "ubuntu") ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [var.cpu_architecture == "arm64" ? "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*" : "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = [var.cpu_architecture]
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

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.private_subnet_cidrs
    description = "ICMP from private subnets (Ping and PMTUD)"
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
  ami                         = coalesce(var.ami_id, var.os_type == "ubuntu" ? one(data.aws_ami.ubuntu[*].id) : (var.os_type == "al2023" ? one(data.aws_ami.al2023[*].id) : one(data.aws_ami.amazon_linux_2[*].id)))
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.nat_instance.id]
  associate_public_ip_address = true
  source_dest_check           = false
  key_name                    = var.key_name

  user_data = var.os_type == "ubuntu" ? var.user_data_ubuntu : var.user_data_al2


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
