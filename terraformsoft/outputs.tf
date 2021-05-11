# output "EC2" {
#   description = "The name of the EC2"
#   value       = aws_instance.wordpress.id
# }

output "EC2_private_ip" {
  value = aws_instance.wordpress.private_ip
}

output "nat_gateway_ip" {
  value = aws_eip.nat.public_ip
}

output "bastion_ip" {
  value = aws_eip.bastion.public_ip
}

output "Route53_NameServer" {
  value = <<EOT
  ${aws_route53_zone.wordpress.name_servers[0]}
  ${aws_route53_zone.wordpress.name_servers[1]}
  ${aws_route53_zone.wordpress.name_servers[2]}
  ${aws_route53_zone.wordpress.name_servers[3]}
  EOT
}

# output "dnsELB" {
# value = aws_elb.wordpress.dns_name
# }


# output "ssh_private_key_pem" {
#   value = tls_private_key.ssh.private_key_pem
# }

# output "ssh_public_key_pem" {
#   value = tls_private_key.ssh.public_key_pem
# }

# output "key_bastion" {
#   value = "terraform output ssh_private_key_pem > key.txt; chmod 700 key.txt \n scp -i key.txt key.txt ubuntu@${aws_eip.bastion.public_ip}:/home/ubuntu \n ssh -i key.txt ubuntu@${aws_eip.bastion.public_ip}"
# }

# output "key_wordpress" {
#   value = "ssh -i key.txt ubuntu@${aws_instance.wordpress.private_ip}"
# }

# output "userdata" {
#   value = "\n${data.template_file.init.*.rendered}"
# }

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cloudFront" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}