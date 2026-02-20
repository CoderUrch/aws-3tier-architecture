# 1. Generate a random password
resource "random_password" "mysql_password" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

# 2. Store it in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "mysql-db-pass"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.mysql_password.result
}


resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "mysql-subnet-group"
  description = "Subnet group for free-tier MySQL"
  subnet_ids  = var.dbtier

  tags = {
    Name = "mysql-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier              = "mysql-db"
  engine                  = "mysql"
  engine_version          = "8.0"      # AWS will pick a valid minor version
  instance_class          = "db.t4g.micro"

  allocated_storage       = 20
  max_allocated_storage   = 20   # MUST NOT AUTO-SCALE ABOVE 20 GiB

  db_name                 = "mydb"
  username                = "admin"
  password                = aws_secretsmanager_secret_version.db_password_version.secret_string

  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [var.db_sg]

  publicly_accessible     = false
  multi_az                = false      # MUST BE FALSE FOR FREE TIER
  storage_type            = "gp2"      # gp3 is OK too

  skip_final_snapshot     = true

  tags = {
    Name = "mysql-db"
  }
}
