#16. Creation du load balancer (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb#instances)
resource "aws_elb" "wordpressLoadBalancer" {
  name = "wordpress-alb"
  # availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]

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

  instances                   = [aws_instance.Instance_EC2.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  security_groups = [
    aws_security_group.wordpress-security.id
  ]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.prive.id
  ]

  tags = {
    Name = "wordpress-elb"
  }
}

# Create a new load balancer attachment
resource "aws_elb_attachment" "wordpress-elb-attachment" {
  elb      = aws_elb.wordpressLoadBalancer.id
  instance = aws_instance.Instance_EC2.id
}

#13. Il nous manque une IP Elastic pour notre NAT
resource "aws_eip" "nat_eip" {
  vpc = true
  # network_interface         = aws_network_interface.wordpress-network_interface-1.id
  # associate_with_private_ip = "10.0.1.50"
  # # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  # depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "IP Public NAT"
  }

}

#13. On rajoute une IP Elastic pour notre Bastion
resource "aws_eip" "bastion" {
  vpc = true
  # network_interface         = aws_network_interface.wordpress-network_interface-1.id
  # associate_with_private_ip = "10.0.1.50"
  # # Dans la doc(https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip), on doit indiquer que notre IP publique dépends de notre gateway. On rajoute donc le flag "depends_on"
  # depends_on = [aws_internet_gateway.gw]
  instance = aws_instance.Bastion-Host.id
  tags = {
    Name = "IP Public NAT"
  }

}