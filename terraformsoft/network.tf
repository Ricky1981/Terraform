# On crée une table de routage pour notre réseau privé
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.wordpress.id
  tags = {
    Name = "private-route-table"
  }
}

# # On crée une table de routage pour notre réseau privé
# resource "aws_route_table" "privateelb" {
#   vpc_id = aws_vpc.wordpress.id
#   tags = {
#     Name = "private-route-table"
#   }
# }

# resource "aws_route" "privateelb" {
#   route_table_id         = aws_route_table.privateelb.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat-gw.id
# }

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
}

# Puis on associe notre table de routage privée avec notre sous-reseau privée
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.prive.id
  route_table_id = aws_route_table.private.id
}



# On crée une table de routage pour notre réseau public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.wordpress.id
  #   route {
  #     # On autorise tout le traffic  
  #     cidr_block = "0.0.0.0/0"
  #     # On pointe sur la Gateway précédemment créée
  #     gateway_id = aws_internet_gateway.gw.id
  #   }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Puis on associe notre table de routage public avec notre sous-reseau public
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "privateelb" {
  subnet_id      = aws_subnet.priveelb.id
  route_table_id = aws_route_table.public.id
}


# #6. Creation de l'interface reseau avec une IP dans le sous-réseau que nous venons de créer à l'étape 3 
# # Cette interface sera celle qui disposera d'une IP Publique qui pointera sur EC2
# resource "aws_network_interface" "wordpress" {
#   description = "wordpress-network_interface"
#   subnet_id   = aws_subnet.public.id
#   private_ips = ["10.0.1.50"]
#   # Ajout du groupe de securité crée à l'étape 2
#   security_groups = [aws_security_group.wordpress.id]
#   tags = {
#     Name = "Interface Réseau de WordPress - Subnet - Public"
#   }
# }