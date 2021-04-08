#10. On ajoute notre passerelle internet
resource "aws_internet_gateway" "gw" {
  # depends_on = [
  #   aws_vpc.wordpress,
  #   aws_subnet.public,
  #   aws_subnet.prive
  # ]
  vpc_id = aws_vpc.wordpress.id

  tags = {
    Name = "WordPress Internet Gateway"
  }
}

#14. On va ajouter notre NAT Gateway (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  # depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "gw NAT"
  }
}

#13. Il nous manque une IP Elastic pour notre NAT
resource "aws_eip" "nat" {
  vpc = true
  # network_interface         = aws_network_interface.wordpress.id
  # associate_with_private_ip = "10.0.1.50"
  # # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  # depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "IP Public NAT"
  }

}

resource "aws_eip" "route53" {
  # instance = aws_instance.web.id
  vpc = true
}