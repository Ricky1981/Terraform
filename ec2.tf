#7. Configuration de notre instance EC2
resource "aws_instance" "MonPremierServeur_EC2" {
  ami           = "ami-00f6fe7d6cbb56a78"
  instance_type = "t2.micro"
  # On ajoute note "key-Pair"
  key_name = "main-key"
  # Optionnelle mais on le met quand meme
  availability_zone = "eu-west-3a"
  # Puis on fait le lien avec l'interface réseau crée à l'étape 6
  network_interface {
    delete_on_termination = false
    network_interface_id  = aws_network_interface.wordpress-network_interface-1.id
    device_index          = 0
  }
  # # Ajout du groupe de sécurité car prend le groupe par défaut d'AWS --> ne se met pas là car sinon erreur "network_interface": conflicts with security_groups. On le met dans la ressource aws_network_interface
  # security_groups = [aws_security_group.wordpress-security.id]
  # On ajoute un tag pour notre instance
  tags = {
    Name = "ubuntu"
  }
}