resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096

}

resource "aws_key_pair" "ssh" {
  key_name   = "key"
  public_key = tls_private_key.ssh.public_key_openssh
  # provisioner "local-exec" {
  #   command = "echo ${tls_private_key.ssh.private_key_pem} > key2.txt"
  # }

}



# resource "null_resource" "example1" {
#   depends_on = [ aws_key_pair.ssh ]
#   provisioner "local-exec" {
#     command = "echo ${tls_private_key.ssh.private_key_pem} > key3.txt"
#   }
# }




data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#7. Configuration de notre instance EC2
resource "aws_instance" "wordpress" {
  # depends_on = [
  #   aws_vpc.wordpress,
  #   aws_subnet.public,
  #   aws_subnet.prive,
  #   aws_security_group.bastion-security
  # ]

  # ami = "ami-00f6fe7d6cbb56a78"
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.prive.id

  # On ajoute note "key-Pair"
  key_name = aws_key_pair.ssh.key_name
  # # Optionnelle mais on le met quand meme
  # availability_zone = "eu-west-3a"

  # vpc_security_group_ids = [aws_security_group.wordpress-security.id]
  security_groups = [aws_security_group.wordpress.id]

  # # Puis on fait le lien avec l'interface réseau crée à l'étape 6
  # network_interface {
  #   delete_on_termination = false
  #   network_interface_id  = aws_network_interface.wordpress.id
  #   device_index          = 0
  # }
  # # Ajout du groupe de sécurité car prend le groupe par défaut d'AWS --> ne se met pas là car sinon erreur "network_interface": conflicts with security_groups. On le met dans la ressource aws_network_interface
  # security_groups = [aws_security_group.wordpress-security.id]
  # On ajoute un tag pour notre instance
  tags = {
    Name = "ubuntu"
  }
}

# # On utilise CloudInit pour Cloud-Init pour provisionner notre bastion avec notre clé ssh (https://learn.hashicorp.com/tutorials/terraform/cloud-init)
# data "template_file" "user_data" {
#   template = file("scripts/add-ssh-web-app.yaml")
# }

# Creating an AWS instance for the Bastion Host, It should be launched in the public Subnet!
resource "aws_instance" "bastion" {
  # ami           = "ami-00f6fe7d6cbb56a78"
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = aws_key_pair.ssh.key_name
  # key_name = data.template_file.userdata
  # Security group ID's
  # vpc_security_group_ids = [aws_security_group.bastion-security.id]
  security_groups = [aws_security_group.bastion.id]

  # # On lui ajoute la clé privé qui me permettra de me connecter sur mon Instance EC2 de mon réseau privé
  # provisioner "file" {
  #   source      = "/home/seb/Documents/ownCloud/OpenClassRoom/Projet_07/main-key.pem"
  #   destination = "/home/ubuntu/main-key.pem"
  #   # connection {
  #   #   type        = "ssh"
  #   #   user        = "ubuntu"
  #   #   private_key = file("/home/seb/Documents/ownCloud/OpenClassRoom/Projet_07/main-key.pem")
  #   #   host        = aws_instance.bastion.public_ip
  #   # }
  # }

  # On fait juste l'update pour gagner du temps
  user_data = <<-EOF
		#! /bin/bash
    sudo apt-get update
	EOF

  # templatefile("${path.module}/templates/userdata.yml",var.region)



  tags = {
    Name = "Bastion"
  }
}

#13. On rajoute une IP Elastic pour notre Bastion
resource "aws_eip" "bastion" {
  vpc = true
  # network_interface         = aws_network_interface.wordpress.id
  # associate_with_private_ip = "10.0.1.50"
  # # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  # depends_on = [aws_internet_gateway.gw]
  instance = aws_instance.bastion.id
  tags = {
    Name = "IP Public bastion"
  }

}




