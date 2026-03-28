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

output "key_pair_name" {
  description = "Key pair name used by the NAT Instance"
  value       = var.key_name != null ? var.key_name : aws_key_pair.key_pair[0].key_name
}

output "private_key_file" {
  description = "Local path to the private key file (if auto-generated)"
  value       = var.key_name != null ? null : "${path.module}/${var.environment}-${var.project_name}-key.pem"
}

output "ssh_command" {
  description = "SSH command to connect to the NAT Instance"
  value       = "ssh -i ${var.key_name != null ? "~/.ssh/${var.key_name}.pem" : "${var.environment}-${var.project_name}-key.pem"} ec2-user@${aws_eip.nat.public_ip}"
}

output "chmod_command" {
  description = "Command to set correct permissions on the private key"
  value       = var.key_name != null ? null : "chmod 400 ${var.environment}-${var.project_name}-key.pem"
}
