#10. On ajoute notre passerelle internet
resource "aws_internet_gateway" "gw" {
  # depends_on = [
  #   aws_vpc.wordpress-vpc,
  #   aws_subnet.public,
  #   aws_subnet.prive
  # ]
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "WordPress Internet Gateway"
  }
}

#14. On va ajouter notre NAT Gateway (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  # depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "gw NAT"
  }
}