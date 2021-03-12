#
# ElastiCache Resources
#
resource "aws_elasticache_subnet_group" "wordpress" {
  name       = "wordpress"
  subnet_ids = [ aws_subnet.prive.id ]
}


resource "aws_elasticache_cluster" "wordpress" {
  cluster_id                   = "cluster-wordpress"
  engine                       = "memcached"
  node_type                    = "cache.t2.micro"
  num_cache_nodes              = 1
  parameter_group_name         = "default.memcached1.6"
  subnet_group_name            = aws_elasticache_subnet_group.wordpress.id
  security_group_ids           = [ aws_security_group.wordpress.id ]
  port                         = 11211
}

