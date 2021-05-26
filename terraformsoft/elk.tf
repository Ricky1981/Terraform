# resource "aws_elasticsearch_domain" "elk" {
#   domain_name           = var.elkdomain
#   elasticsearch_version = "7.9"

#   cluster_config {
#     instance_type = "t2.medium.elasticsearch"
#   }


# #   snapshot_options {
# #     automated_snapshot_start_hour = 23
# #   }

#   access_policies = <<POLICY
#     {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Action": "es:*",
#         "Principal": "*",
#         "Effect": "Allow",
#         "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.elkdomain}/*",
#         "Condition": {
#             "IpAddress": {"aws:SourceIp": ["${var.ipPerso}"]}
#         }
#       },
#       {
#         "Action": "es:*",
#         "Principal": "*",
#         "Effect": "Allow",
#         "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.elkdomain}/*",
#         "Condition": {
#             "IpAddress": {"aws:SourceIp": ["${aws_eip.nat.public_ip}"]}
#         }
#       }
#     ]
#     }
#     POLICY
 

#    ebs_options {
#      ebs_enabled = true
#      volume_type = "gp2"
#      volume_size = 10
#    } 
 
#   tags = {
#     Domain = "ElkDomain"
#   }
# }