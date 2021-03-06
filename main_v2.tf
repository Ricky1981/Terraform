terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # La version est optionnelle apparemment... A tester...
      version = "~> 3.0"
    }
  }
}

# Configuration du provider AWS
provider "aws" {
  # On utilise une connection par variable d'environnement.
  # Voir https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  # Si les clés changent, penser à faire la modification dans le VagrantFile
}

# Voici les différentes étapes que nous créerons lors de ce projet
# #1. Creation du VPC 
# resource "aws_vpc" "wordpress-vpc" {
#   cidr_block = "10.0.0.0/22"
#   tags = {
#     Name = "wordpress"
#   }
# }

# #2. Creation du Group de Securité pour autoriser les ports 22, 80, 443 et 3306 
# resource "aws_security_group" "wordpress-security" {
#   name        = "allow_web_traffic"
#   description = "Allow Web inbound traffic"
#   vpc_id      = aws_vpc.wordpress-vpc.id

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     # On peut indiquer ici qu'une plage d'adresse autorisé par exemple. Mais on va dire que tout le monde peut utiliser le 443
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "MySQL"
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port = 0
#     to_port   = 0
#     # -1 Indique tous les protocole
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow_web"
#   }
# }

# #3. Creation du subnet 1 
# resource "aws_subnet" "wordpress-subnet-1" {
#   # On pointe sur le VPC que nous avons créée
#   vpc_id     = aws_vpc.wordpress-vpc.id
#   cidr_block = "10.0.1.0/24"
#   # Optionnelle
#   availability_zone = "eu-west-3a"
#   tags = {
#     Name = "wordpress-subnet-1"
#   }
# }

# #4. Création d'un autre subnet car sinon erreur dans Terraform suivant : "please add subnets to cover at least 2 availability zones".
# resource "aws_subnet" "wordpress-subnet-2" {
#   # On pointe sur le VPC que nous avons créée
#   vpc_id     = aws_vpc.wordpress-vpc.id
#   cidr_block = "10.0.2.0/24"
#   # Optionnelle
#   availability_zone = "eu-west-3b"
#   tags = {
#     Name = "wordpress-subnet-2"
#   }
# }

#5. Création d'un Groupe de sous-réseau car RDS me pose problème...
resource "aws_db_subnet_group" "default" {
  name        = "wordpress-subnet-group"
  description = "RDS subnet group"
  # # Ci-dessous, Pas bon, je dois avoir au moins 2 sous-réseau
  # subnet_ids  = [aws_subnet.wordpress-subnet.id]
  subnet_ids = [aws_subnet.wordpress-subnet-1.id, aws_subnet.wordpress-subnet-2.id]
}

#6. Creation de l'interface reseau avec une IP dans le sous-réseau que nous venons de créer à l'étape 3 
# Cette interface sera celle qui disposera d'une IP Publique qui pointera sur EC2
resource "aws_network_interface" "wordpress-network_interface-1" {
  subnet_id   = aws_subnet.wordpress-subnet-1.id
  private_ips = ["10.0.1.50"]
  # Ajout du groupe de securité crée à l'étape 2
  security_groups = [aws_security_group.wordpress-security.id]
  tags = {
    Name = "Interface Réseau de WordPress - Subnet - 1 - Contient l'IP public de EC2"
  }
}

# # A Suppr
# #6 bis. Idem que l'étape 6 mais utile car le ALB attend 2 sous-reseau --> Mais à voir si on ne peut pas le supprimer...
# resource "aws_network_interface" "wordpress-network_interface-2" {
#   subnet_id       = aws_subnet.wordpress-subnet-2.id
#   private_ips     = ["10.0.2.50"]
#   # Ajout du groupe de securité
#   security_groups = [aws_security_group.wordpress-security.id]
#   tags = {
#     Name = "Interface Réseau de WordPress - Subnet - 2 - Utile seulement dans notre cas pour le LoadBalancer"
#   }
# }

# #7. Configuration de notre instance EC2
# resource "aws_instance" "MonPremierServeur_EC2" {
#   ami           = "ami-00f6fe7d6cbb56a78"
#   instance_type = "t2.micro"
#   # On ajoute note "key-Pair"
#   key_name = "main-key"
#   # Optionnelle mais on le met quand meme
#   availability_zone = "eu-west-3a"
#   # Puis on fait le lien avec l'interface réseau crée à l'étape 6
#   network_interface {
#     delete_on_termination = false
#     network_interface_id  = aws_network_interface.wordpress-network_interface-1.id
#     device_index          = 0
#   }
#   # # Ajout du groupe de sécurité car prend le groupe par défaut d'AWS --> ne se met pas là car sinon erreur "network_interface": conflicts with security_groups. On le met dans la ressource aws_network_interface
#   # security_groups = [aws_security_group.wordpress-security.id]
#   # On ajoute un tag pour notre instance
#   tags = {
#     Name = "ubuntu"
#   }
# }

# #8. Configuration d'une option Group qui sera necessaire pour MemCached
# # (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_option_group)
# resource "aws_db_option_group" "RDS-OptionGroup" {
#   name                     = "wordpress-option-group"
#   option_group_description = "WordPress Option Group"
#   engine_name              = "mysql"
#   major_engine_version     = "5.7"

#   #Puis on ajoute l'option "MemCached"
#   option {
#     option_name                    = "MEMCACHED"
#     port                           = 11211
#     vpc_security_group_memberships = [aws_security_group.wordpress-security.id]

#     option_settings {
#       name  = "BACKLOG_QUEUE_LIMIT"
#       value = 1024
#     }

#     option_settings {
#       name  = "BINDING_PROTOCOL"
#       value = "auto"
#     }

#     option_settings {
#       name  = "CAS_DISABLED"
#       value = 0
#     }

#     option_settings {
#       name  = "CHUNK_SIZE"
#       value = 48
#     }

#     option_settings {
#       name  = "CHUNK_SIZE_GROWTH_FACTOR"
#       value = 1.25
#     }
#   }
# }


# #10. On ajoute notre passerelle internet
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.wordpress-vpc.id

#   tags = {
#     Name = "WordPress Internet Gateway"
#   }
# }

# #11. On crée une table de routage qui permet d'indiquer que la passerelle internet créée à l'étape 10 a le droit de communiquer avec le reste du monde (0.0.0.0/0)
# resource "aws_route_table" "wordpress-route-table" {
#   vpc_id = aws_vpc.wordpress-vpc.id

#   route {
#     # On autorise tout le traffic  
#     cidr_block = "0.0.0.0/0"
#     # On pointe sur la Gateway précédemment créée
#     gateway_id = aws_internet_gateway.gw.id
#   }

#   route {
#     # On autorise le traffic IP v6
#     ipv6_cidr_block = "::/0"
#     # On pointe sur la Gateway précédemment créée
#     gateway_id = aws_internet_gateway.gw.id
#   }

#   tags = {
#     Name = "WordPress EC2 Route Table"
#   }
# }

# #11bis. Creation d'une autre Route Table indiquer cette fois-ci que c'est notre passerelle NAT qui a le droit de communiquer avec le reste du monde (en sortie) 
# resource "aws_route_table" "NAT-route-table" {
#   vpc_id = aws_vpc.wordpress-vpc.id

#   route {
#     # On autorise tout le traffic  
#     cidr_block = "0.0.0.0/0"
#     # On pointe sur la Gateway précédemment créée
#     nat_gateway_id = aws_nat_gateway.nat-gw.id
#   }

#   tags = {
#     Name = "WordPress NAT Route Table"
#   }
# }

# #12. Puis on fait une association entre notre sous-reseau "1" avec ma table de routage
# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.wordpress-subnet-1.id
#   route_table_id = aws_route_table.wordpress-route-table.id
# }

# #12bis. Idem avec le sous-reseau "2" 
# resource "aws_route_table_association" "b" {
#   subnet_id      = aws_subnet.wordpress-subnet-2.id
#   route_table_id = aws_route_table.wordpress-route-table.id
# }

#13. Il nous manque une IP Elastic qu'on va "lier" à notre interface reseau (aws_network_interface) de l'étape 6 et qui pointera sur EC2
resource "aws_eip" "ip_public" {
  vpc                       = true
  network_interface         = aws_network_interface.wordpress-network_interface-1.id
  associate_with_private_ip = "10.0.1.50"
  # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "IP Public EC2"
  }

}

#13bis. Je crée une autre IP Elastic que j'affecterai à ma passerelle NAT et qui pointera toujours sur l'IP privé de mon instance EC2
resource "aws_eip" "ip_public_NAT" {
  vpc = true
  ## Je supprime la ligne ci-dessous car conflit avec une IP publique et en plus c'est indiqué dans la doc
  # network_interface         = aws_network_interface.wordpress-network_interface-1.id
  associate_with_private_ip = "10.0.1.50"
  # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "IP Public NAT"
  }
}

#14. On va ajouter notre NAT Gateway (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.ip_public_NAT.id
  subnet_id     = aws_subnet.wordpress-subnet-1.id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "gw NAT"
  }
}

#15. Ajout de route53
# On commence par la zone (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone)
resource "aws_route53_zone" "route53-zone" {
  name = "projet07.tk"
}

#15bis. Puis les records (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
resource "aws_route53_record" "projet06tk" {
  zone_id = aws_route53_zone.route53-zone.zone_id
  name    = "projet07.tk"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.ip_public.public_ip]
}

#15bis
resource "aws_route53_record" "wwwprojet06tk" {
  zone_id = aws_route53_zone.route53-zone.zone_id
  name    = "www.projet07.tk"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.ip_public.public_ip]
}

#15bis
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

#16. Creation du load balancer (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb#instances)
resource "aws_elb" "applicationLoadBalancer" {
  name = "wordpress-alb"
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

output "public_ip_NAT" {
  value = aws_eip.ip_public_NAT.public_ip
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
