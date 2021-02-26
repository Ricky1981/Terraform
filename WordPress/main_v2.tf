terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # La version est optionnelle apparemment... A tester...
      version = "~> 3.0"
    }
  }
}

# Configuration du provider AWS
provider "aws" {
  # On selectionne la region de Paris
  region = "eu-west-3"
  # Authentification par jeton... Mais ce n'est pas le plus "secure"
  access_key = "AKIAIMQK2L7HYPRED6QA"
  secret_key = "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"
}

# Voici les différentes étapes que nous créerons lors de ce projet
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
    from_port   = 0
    to_port     = 0
    # -1 Indique tous les protocole
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#3. Creation du subnet 
resource "aws_subnet" "wordpress-subnet-1" {
  # On pointe sur le VPC que nous avons créée
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.1.0/24"
  # Optionnelle
  availability_zone = "eu-west-3a"
  tags = {
    Name = "wordpress-subnet"
  }
}

#3bis. Création d'un Groupe de sous-réseau car RDS me pose problème...
resource "aws_db_subnet_group" "default" {
  name        = "wordpress-subnet-group"
  description = "Terraform example RDS subnet group"
  # # Ci-dessous, Pas bon, je dois avoir au moins 2 sous-réseau
  # subnet_ids  = [aws_subnet.wordpress-subnet.id]
  subnet_ids  = [aws_subnet.wordpress-subnet-1.id, aws_subnet.wordpress-subnet-2.id]
}

#3ter. Création d'un autre subnet car sinon erreur dans Terraform suivant : "please add subnets to cover at least 2 availability zones"
resource "aws_subnet" "wordpress-subnet-2" {
  # On pointe sur le VPC que nous avons créée
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.2.0/24"
  # Optionnelle
  availability_zone = "eu-west-3b"
  tags = {
    Name = "wordpress-subnet"
  }
}

#4. Creation de l'interface reseau avec une IP dans le sous-réseau que nous venons de créer à l'étape 3 
resource "aws_network_interface" "wordpress-network_interface-1" {
  subnet_id       = aws_subnet.wordpress-subnet-1.id
  private_ips     = ["10.0.1.50"]
  # Ajout du groupe de securité
  security_groups = [aws_security_group.wordpress-security.id]
  tags = {
    Name = "Interface Réseau de WordPress"
  }
}

resource "aws_network_interface" "wordpress-network_interface-2" {
  subnet_id       = aws_subnet.wordpress-subnet-2.id
  private_ips     = ["10.0.2.50"]
  # Ajout du groupe de securité
  security_groups = [aws_security_group.wordpress-security.id]
  tags = {
    Name = "Interface Réseau de WordPress"
  }
}

# resource "aws_network_interface_attachment" "test" {
#   instance_id          = aws_instance.MonPremierServeur_EC2.id
#   network_interface_id = aws_network_interface.wordpress-network_interface-2.id
#   device_index         = 1
# }


# Configuration de notre premiere instance EC2 (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
resource "aws_instance" "MonPremierServeur_EC2" {
    ami = "ami-00f6fe7d6cbb56a78"
    instance_type = "t2.micro"
    # On ajoute note "key-Pair"
    key_name = "main-key"
    # Optionnelle mais on le met quand meme
    availability_zone = "eu-west-3a"
    network_interface {
      delete_on_termination = false
      network_interface_id = aws_network_interface.wordpress-network_interface-1.id
      device_index         = 0
    }
    # # Ajout du groupe de sécurité car prend le groupe par défaut d'AWS --> ne se met pas là car sinon erreur "network_interface": conflicts with security_groups. On le met dans la ressource aws_network_interface
    # security_groups = [aws_security_group.wordpress-security.id]
    # On ajoute un tag pour notre instance
    tags = {
      Name = "ubuntu"
    }  
}



# Configuration de notre instance RDS (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
resource "aws_db_instance" "MonPremierServeur_RDS" {
  identifier = "mysql"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  # On respecte les prérequis à WordPress à savoir MySQL >= 5.6
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  # On va appeler la BDD wordpress (https://aws.amazon.com/fr/getting-started/hands-on/deploy-wordpress-with-amazon-rds/2/)
  name                 = "wordpress"
  username             = "admin"
  password             = "adminadmin"
  parameter_group_name = "default.mysql5.7"
  # Permet de pouvoir supprimer l'instance sans faire de SnapShot
  skip_final_snapshot  = true
  # # Permet de se connecter en dehors du VPC ce qui est mon cas avec MySQL WorkBench
  # publicly_accessible  = true
  # Optionnelle mais on le met quand meme
  availability_zone = "eu-west-3a"
  vpc_security_group_ids = [aws_security_group.wordpress-security.id]
  db_subnet_group_name = aws_db_subnet_group.default.id
}

# Ci-dessus, on a un truc qui semble fonctionner mais sans accès publique. Je ne peux donc pas acceder à mon instance EC2
# Par contre j'ai bien accès à ma BDD mais ce n'est pas normal car elle n'est pas dans le meme VPC que mon EC2...
# Je verrai plus tard, on va déjà tenter d'acceder à notre EC2 via une IP publique

# On commence par la passerelle internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.wordpress-vpc.id
}

# Petite table de routage à mettre en place 
#3. Create Custom Route Table 
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
    ipv6_cidr_block        = "::/0"
    # On pointe sur la Gateway précédemment créée
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "WordPress Route Table"
  }
}

# Puis on fait une association entre notre sous-reseau (j'en laisse un de côté qui ne me sert uniquement pour RDS) avec ma table de routage
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.wordpress-subnet-1.id
  route_table_id = aws_route_table.wordpress-route-table.id
}

# Puis on fait une association entre notre sous-reseau (j'en laisse un de côté qui ne me sert uniquement pour RDS) avec ma table de routage
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.wordpress-subnet-2.id
  route_table_id = aws_route_table.wordpress-route-table.id
}

# Il nous manque une IP Elastic qu'on va "lier" à notre interface reseau (aws_network_interface)
resource "aws_eip" "ip_public" {
  vpc                       = true
  network_interface         = aws_network_interface.wordpress-network_interface-1.id
  associate_with_private_ip = "10.0.1.50"
  # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  depends_on = [aws_internet_gateway.gw]
}


# Ajout de route53
# On commence par la zone (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone)
resource "aws_route53_zone" "route53-zone" {
  name = "projet07.tk"
}

# Puis le record (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
resource "aws_route53_record" "projet06tk" {
  zone_id = aws_route53_zone.route53-zone.zone_id
  name    = "projet07.tk"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.ip_public.public_ip]
}

resource "aws_route53_record" "wwwprojet06tk" {
  zone_id = aws_route53_zone.route53-zone.zone_id
  name    = "www.projet07.tk"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.ip_public.public_ip]
}

resource "aws_route53_record" "route53-zone" {
  allow_overwrite = true
  name            = "projet07.tk"
  ttl             = 30
  type            = "NS"
  zone_id         = aws_route53_zone.route53-zone.zone_id

  records = [
    aws_route53_zone.route53-zone.name_servers[0],
    aws_route53_zone.route53-zone.name_servers[1],
    aws_route53_zone.route53-zone.name_servers[2],
    aws_route53_zone.route53-zone.name_servers[3],
  ]
}

# Create a new load balancer (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb#instances)
resource "aws_elb" "applicationLoadBalancer" {
  name               = "wordpress-alb"
  # availability_zones = ["eu-west-3a", "eu-west-3b"]

  # access_logs {
  #   bucket        = "foo"
  #   bucket_prefix = "bar"
  #   interval      = 60
  # }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # listener {
  #   instance_port      = 8000
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.MonPremierServeur_EC2.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  security_groups = [
    aws_security_group.wordpress-security.id
  ]

  subnets = [ 
    aws_subnet.wordpress-subnet-1.id,
    aws_subnet.wordpress-subnet-2.id 
  ]

  tags = {
    Name = "wordpress-elb"
  }
}

output "public_ip" {
    value = aws_eip.ip_public.public_ip
}

output "public_dns" {
    value = aws_eip.ip_public.public_dns
}

output "RDS_endpoint" {
    value = aws_db_instance.MonPremierServeur_RDS.endpoint
}

output "ssh_connection" {
  value = "ssh -i main-key.pem ubuntu@${aws_eip.ip_public.public_dns}"
}

output "Route53_NameServer" {
  value = <<EOT
  ${aws_route53_zone.route53-zone.name_servers[0]}
  ${aws_route53_zone.route53-zone.name_servers[1]}
  ${aws_route53_zone.route53-zone.name_servers[2]}
  ${aws_route53_zone.route53-zone.name_servers[3]}
  EOT
}
