#6. Creation de l'interface reseau avec une IP dans le sous-réseau que nous venons de créer à l'étape 3 
# Cette interface sera celle qui disposera d'une IP Publique qui pointera sur EC2
resource "aws_network_interface" "wordpress-network_interface-1" {
  description = "wordpress-network_interface-1"
  subnet_id   = aws_subnet.public.id
  private_ips = ["10.0.1.50"]
  # Ajout du groupe de securité crée à l'étape 2
  security_groups = [aws_security_group.wordpress-security.id]
  tags = {
    Name = "Interface Réseau de WordPress - Subnet - 1 - Contient l'IP public de EC2"
  }
}



/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.wordpress-vpc.id
  tags = {
    Name = "private-route-table"
  }
}



/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.wordpress-vpc.id
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
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.prive.id
  route_table_id = aws_route_table.private.id
}