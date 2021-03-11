data "template_file" "privatekey" {
  template = file("${path.module}/templates/key")

  vars = {
    key = tls_private_key.ssh.private_key_pem
  }
}

data "template_file" "publickey" {
  template = file("${path.module}/templates/key")

  vars = {
    key = tls_private_key.ssh.public_key_pem
  }
}

data "template_file" "hosts" {
  template = file("${path.module}/templates/hosts")

  vars = {
    ip_bastion = aws_eip.bastion.public_ip
    ip_ec2 = aws_instance.wordpress.private_ip
  }
}

data "template_file" "bastionhosts" {
  template = file("${path.module}/templates/bastionhosts")

  vars = {
    ip_ec2 = aws_instance.wordpress.private_ip
  }
}

resource "null_resource" "privatekey" {
  provisioner "local-exec" {
    command = "echo \"${data.template_file.privatekey.rendered}\" > ${var.PrivateKey}"
  }
}

resource "null_resource" "publickey" {
  provisioner "local-exec" {
    command = "echo \"${data.template_file.publickey.rendered}\" > ${var.PublicKey}"
  }
}

resource "null_resource" "hosts" {
  provisioner "local-exec" {
    command = "echo \"${data.template_file.hosts.rendered}\" > ${var.hosts}"
  }
}

resource "null_resource" "hostsreplace" {
  depends_on = [ 
    aws_instance.wordpress,
    aws_eip.bastion
   ]
  provisioner "local-exec" {
    command = "sudo cp -f ${var.hosts} /etc/hosts; chmod 700 ${var.PrivateKey}"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "bastionhosts" {
  provisioner "local-exec" {
    command = "echo \"${data.template_file.bastionhosts.rendered}\" > ${var.bastionhosts}"
  }
}


