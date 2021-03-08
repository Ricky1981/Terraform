output "EC2" {
  description = "The name of the EC2"
  value       = aws_instance.Instance_EC2.id
}

output "EC2_private_ip" {
  value = aws_instance.Instance_EC2.private_ip
}

output "nat_gateway_ip" {
  value = aws_eip.nat_eip.public_ip
}

output "bastion_ip" {
  value = aws_eip.bastion.public_ip
}

output "ssh_private_key_pem" {
  value = tls_private_key.ssh.private_key_pem
}

output "ssh_public_key_pem" {
  value = tls_private_key.ssh.public_key_pem
}