#16. Creation du load balancer (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb#instances)
resource "aws_elb" "wordpress" {
  name = "wordpress-elb"
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
  #   instance_port      = 443
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

  instances                   = [aws_instance.wordpress.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  security_groups = [
    aws_security_group.wordpress.id
  ]

  subnets = [
    aws_subnet.priveelb.id,
    aws_subnet.public.id
  ]

  tags = {
    Name = "wordpress-elb"
  }
}

# Create a new load balancer attachment
resource "aws_elb_attachment" "wordpress" {
  elb      = aws_elb.wordpress.id
  instance = aws_instance.wordpress.id
}



