resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "take-home-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "11.9" 
  master_username         = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string).username
  master_password         = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string).password
  database_name           = "takehome"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.private_sg.id]
  skip_final_snapshot     = true

  tags = {
    Name = "TakeHomeAuroraCluster"
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count                   = 1 
  identifier              = "take-home-aurora-instance-${count.index}"
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  instance_class          = "db.r5.large" 
  engine                  = aws_rds_cluster.aurora_cluster.engine

  tags = {
    Name = "TakeHomeAuroraInstance"
  }
}