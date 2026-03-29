output "nat_instance_id" {
  description = "ID of the NAT Instance"
  value       = aws_instance.nat_instance.id
}

output "nat_instance_arn" {
  description = "ARN of the NAT Instance"
  value       = aws_instance.nat_instance.arn
}

output "nat_instance_public_ip" {
  description = "Public IP (EIP) of the NAT Instance"
  value       = aws_eip.nat.public_ip
}

output "nat_instance_private_ip" {
  description = "Private IP of the NAT Instance"
  value       = aws_instance.nat_instance.private_ip
}

output "nat_network_interface_id" {
  description = "Primary network interface ID of the NAT Instance"
  value       = aws_instance.nat_instance.primary_network_interface_id
}

output "nat_security_group_id" {
  description = "Security Group ID of the NAT Instance"
  value       = aws_security_group.nat_instance.id
}


