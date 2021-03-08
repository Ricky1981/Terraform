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
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

#1. Creation du VPC 
resource "aws_vpc" "wordpress-vpc" {
  cidr_block           = "10.0.0.0/22"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "wordpressVPC"
  }
}



#3. Creation du subnet public
resource "aws_subnet" "public" {
  # depends_on = [aws_vpc.wordpress-vpc]
  # On pointe sur le VPC que nous avons créée
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.1.0/24"
  # Optionnelle
  availability_zone = "eu-west-3a"

  # # Enabling automatic public IP assignment on instance launch!
  # map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-subnet-public"
  }
}

resource "aws_subnet" "prive" {
  depends_on = [
    aws_vpc.wordpress-vpc,
    aws_subnet.public
  ]
  # On pointe sur le VPC que nous avons créée
  vpc_id     = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.2.0/24"
  # Optionnelle
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = false
  tags = {
    Name = "wordpress-subnet-private"
  }
}

#2. Creation du Group de Securité pour autoriser les ports 22, 80, 443 et 3306 
resource "aws_security_group" "wordpress-security" {
  depends_on = [
    aws_vpc.wordpress-vpc,
    aws_subnet.public,
    aws_subnet.prive
  ]

  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.wordpress-vpc.id

  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   # On peut indiquer ici qu'une plage d'adresse autorisé par exemple. Mais on va dire que tout le monde peut utiliser le 443
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   description = "HTTP"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   description = "MySQL"
  #   from_port   = 3306
  #   to_port     = 3306
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

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

#2. Creation du Group de Securité pour notre bastion 
resource "aws_security_group" "bastion-security" {
  depends_on = [
    aws_vpc.wordpress-vpc,
    aws_subnet.public,
    aws_subnet.prive
  ]

  name        = "bastion_allow_traffic"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    description = "Bastion SSH"
    from_port   = 22
    to_port     = 22
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
    Name        = "bastion_SecurityGroup"
    Description = "bastion_SecurityGroup"
  }
}

# # create VPC Network access control list
# resource "aws_network_acl" "wordpress-acl" {
#   #default_network_acl_id = aws_vpc.wordpress-vpc.default_network_acl_id
#   vpc_id     = aws_vpc.wordpress-vpc.id
#   subnet_ids = [aws_subnet.wordpress-subnet-1.id, aws_subnet.wordpress-subnet-2.id, aws_subnet.wordpress-subnet-3.id]

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   # allow egress port 22 
#   egress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   # allow egress port 80 
#   egress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   tags = {
#     Name = "allow_web_ACL"
#   }
# } # end resource

# resource "aws_default_vpc_dhcp_options" "default" {
#   tags = {
#     Name = "WordPress DHCP Option Set"
#   }
# }

