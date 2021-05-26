resource "aws_cloudfront_distribution" "wordpress" {
  origin {
    domain_name = aws_elb.wordpress.dns_name
    origin_id   = "ELB-${aws_elb.wordpress.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      # origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2", "SSLv3"]
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  enabled = true
  #   is_ipv6_enabled     = true
  comment             = "Some comment"
  #default_root_object = "index.php"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "ELB-${aws_elb.wordpress.name}"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    # min_ttl                = 0
    # default_ttl            = 0
    # max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
