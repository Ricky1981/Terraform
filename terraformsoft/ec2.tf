resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name = "DummyMachine"
  public_key = tls_private_key.ssh.public_key_openssh
}


#7. Configuration de notre instance EC2
resource "aws_instance" "Instance_EC2" {
  # depends_on = [
  #   aws_vpc.wordpress-vpc,
  #   aws_subnet.public,
  #   aws_subnet.prive,
  #   aws_security_group.bastion-security
  # ]

  ami           = "ami-00f6fe7d6cbb56a78"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.prive.id

  # On ajoute note "key-Pair"
  key_name = aws_key_pair.ssh.key_name
  # # Optionnelle mais on le met quand meme
  # availability_zone = "eu-west-3a"

  # vpc_security_group_ids = [aws_security_group.wordpress-security.id]
  security_groups = [aws_security_group.wordpress-security.id]

  # # Puis on fait le lien avec l'interface réseau crée à l'étape 6
  # network_interface {
  #   delete_on_termination = false
  #   network_interface_id  = aws_network_interface.wordpress-network_interface-1.id
  #   device_index          = 0
  # }
  # # Ajout du groupe de sécurité car prend le groupe par défaut d'AWS --> ne se met pas là car sinon erreur "network_interface": conflicts with security_groups. On le met dans la ressource aws_network_interface
  # security_groups = [aws_security_group.wordpress-security.id]
  # On ajoute un tag pour notre instance
  tags = {
    Name = "ubuntu"
  }
}

# Creating an AWS instance for the Bastion Host, It should be launched in the public Subnet!
resource "aws_instance" "Bastion-Host" {
  #  depends_on = [
  #   aws_instance.Instance_EC2
  # ]

  ami           = "ami-00f6fe7d6cbb56a78"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = aws_key_pair.ssh.key_name

  # Security group ID's
  # vpc_security_group_ids = [aws_security_group.bastion-security.id]
  security_groups = [aws_security_group.wordpress-security.id]

  # # On lui ajoute la clé privé qui me permettra de me connecter sur mon Instance EC2 de mon réseau privé
  # provisioner "file" {
  #   source      = "/home/seb/Documents/ownCloud/OpenClassRoom/Projet_07/main-key.pem"
  #   destination = "/home/ubuntu/main-key.pem"
  #   # connection {
  #   #   type        = "ssh"
  #   #   user        = "ubuntu"
  #   #   private_key = file("/home/seb/Documents/ownCloud/OpenClassRoom/Projet_07/main-key.pem")
  #   #   host        = aws_instance.Bastion-Host.public_ip
  #   # }
  # }

  tags = {
    Name = "Bastion"
  }
}





