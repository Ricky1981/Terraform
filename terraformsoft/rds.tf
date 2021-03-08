#9. Configuration de notre instance RDS (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
resource "aws_db_instance" "MonPremierServeur_RDS" {
  identifier        = "mysql"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  # On respecte les prérequis à WordPress à savoir MySQL >= 5.6
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  # On va appeler la BDD wordpress (https://aws.amazon.com/fr/getting-started/hands-on/deploy-wordpress-with-amazon-rds/2/)
  name                 = "wordpress"
  username             = "admin"
  password             = "adminadmin"
  parameter_group_name = "default.mysql5.7"
  # On rajoute notre option Group crée à l'étape 8
  option_group_name = aws_db_option_group.RDS-OptionGroup.id
  # Permet de pouvoir supprimer l'instance sans faire de SnapShot --> pratique lorsqu'on fait un "terraform destroy"
  skip_final_snapshot = true
  # # Permet de se connecter en dehors du VPC ce qui est mon cas avec MySQL WorkBench
  # publicly_accessible  = true
  # Optionnelle mais on le met quand meme
  availability_zone = "eu-west-3a"
  # On lie notre instance avec notre groupe de securité crée à l'étape 2
  vpc_security_group_ids = [aws_security_group.wordpress-security.id]
  # Ajout du group de l'étape 5 qui contient les 2 sous réseaux subnet-1 et subnet-2
  db_subnet_group_name = aws_db_subnet_group.default.id
}

#5. Création d'un Groupe de sous-réseau car RDS me pose problème...
resource "aws_db_subnet_group" "default" {
  name        = "wordpress-subnet-group"
  description = "RDS subnet group"
  # # Ci-dessous, Pas bon, je dois avoir au moins 2 sous-réseau
  # subnet_ids  = [aws_subnet.wordpress-subnet.id]
  subnet_ids = [aws_subnet.public.id, aws_subnet.prive.id]
}

#8. Configuration d'une option Group qui sera necessaire pour MemCached
# (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_option_group)
resource "aws_db_option_group" "RDS-OptionGroup" {
  name                     = "wordpress-option-group"
  option_group_description = "WordPress Option Group"
  engine_name              = "mysql"
  major_engine_version     = "5.7"

  #Puis on ajoute l'option "MemCached"
  option {
    option_name                    = "MEMCACHED"
    port                           = 11211
    vpc_security_group_memberships = [aws_security_group.wordpress-security.id]

    option_settings {
      name  = "BACKLOG_QUEUE_LIMIT"
      value = 1024
    }

    option_settings {
      name  = "BINDING_PROTOCOL"
      value = "auto"
    }

    option_settings {
      name  = "CAS_DISABLED"
      value = 0
    }

    option_settings {
      name  = "CHUNK_SIZE"
      value = 48
    }

    option_settings {
      name  = "CHUNK_SIZE_GROWTH_FACTOR"
      value = 1.25
    }
  }
}

