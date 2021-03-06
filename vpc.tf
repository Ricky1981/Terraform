#1. Creation du VPC 
resource "aws_vpc" "wordpress-vpc" {
  cidr_block = "10.0.0.0/22"
  tags = {
    Name = "wordpress"
  }
}

#2. Creation du Group de Securité pour autoriser les ports 22, 80, 443 et 3306 
resource "aws_security_group" "wordpress-security" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # On peut indiquer ici qu'une plage d'adresse autorisé par exemple. Mais on va dire que tout le monde peut utiliser le 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    # -1 Indique tous les protocole
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow_web_SecurityGroup"
    Description = "allow_web_SecurityGroup"
  }
}

# create VPC Network access control list
resource "aws_network_acl" "wordpress-acl" {
  vpc_id     = aws_vpc.wordpress-vpc.id
  subnet_ids = [aws_subnet.wordpress-subnet-1.id, aws_subnet.wordpress-subnet-2.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # allow egress port 22 
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # allow egress port 80 
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name = "allow_web_ACL"
  }
} # end resource

#3. Creation du subnet 1 
resource "aws_subnet" "wordpress-subnet-1" {
  # On pointe sur le VPC que nous avons créée
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.1.0/24"
  # Optionnelle
  availability_zone = "eu-west-3a"
  tags = {
    Name = "wordpress-subnet-1"
  }
}

#4. Création d'un autre subnet car sinon erreur dans Terraform suivant : "please add subnets to cover at least 2 availability zones".
resource "aws_subnet" "wordpress-subnet-2" {
  # On pointe sur le VPC que nous avons créée
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.2.0/24"
  # Optionnelle
  availability_zone = "eu-west-3b"
  tags = {
    Name = "wordpress-subnet-2"
  }
}

#10. On ajoute notre passerelle internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "WordPress Internet Gateway"
  }
}

#11. On crée une table de routage qui permet d'indiquer que la passerelle internet créée à l'étape 10 a le droit de communiquer avec le reste du monde (0.0.0.0/0)
resource "aws_route_table" "wordpress-route-table" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    # On autorise tout le traffic  
    cidr_block = "0.0.0.0/0"
    # On pointe sur la Gateway précédemment créée
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    # On autorise le traffic IP v6
    ipv6_cidr_block = "::/0"
    # On pointe sur la Gateway précédemment créée
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "WordPress EC2 Route Table"
  }
}

#11bis. Creation d'une autre Route Table indiquer cette fois-ci que c'est notre passerelle NAT qui a le droit de communiquer avec le reste du monde (en sortie) 
resource "aws_route_table" "NAT-route-table" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    # On autorise tout le traffic  
    cidr_block = "0.0.0.0/0"
    # On pointe sur la Gateway précédemment créée
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "WordPress NAT Route Table"
  }
}

#12. Puis on fait une association entre notre sous-reseau "1" avec ma table de routage
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.wordpress-subnet-1.id
  route_table_id = aws_route_table.wordpress-route-table.id
}

#12bis. Idem avec le sous-reseau "2" 
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.wordpress-subnet-2.id
  route_table_id = aws_route_table.wordpress-route-table.id
}

# Si erreur voir la prochaine fois :
# aws_vpc_dhcp_options
# domain-name: eu-west-3.compute.internal
# domain-name-servers: AmazonProvidedDNS