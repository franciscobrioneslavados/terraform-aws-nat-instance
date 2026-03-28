output "nat_instance_public_ip" {
  description = "IP pública (EIP) de la NAT Instance"
  value       = aws_eip.eip_nat.public_ip
}

output "nat_instance_private_ip" {
  description = "IP privada de la NAT Instance"
  value       = aws_instance.nat_instance.private_ip
}

output "nat_network_interface_id" {
  description = "ENI principal de la NAT Instance"
  value       = aws_instance.nat_instance.primary_network_interface_id
}

output "nat_security_group_id" {
  description = "Security Group ID de la NAT Instance"
  value       = aws_security_group.nat_instance.id
}

output "chmod_command" {
  description = "Comando para configurar la NAT Instance"
  value       = "chmod 400 ${aws_key_pair.key_pair.key_name}.pem"
}

output "ssh_connect_instance" {
  description = "Comando SSH para conectar a la NAT Instance"
  value       = "ssh -i ${aws_key_pair.key_pair.key_name}.pem ec2-user@${aws_eip.eip_nat.public_ip}"
}
