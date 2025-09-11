resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "webtier" {
  count                   = length(var.webtier_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.webtier_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "webtier-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "apptier" {
  count                   = length(var.apptier_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.apptier_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "apptier-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "dbtier" {
  count                   = length(var.dbtier_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.dbtier_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "dbtier-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-igw"
  }
}

resource "aws_eip" "elastic_ip" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}


resource "aws_nat_gateway" "natgw" {
  count         = 2
  allocation_id = aws_eip.elastic_ip[count.index].id
  subnet_id     = aws_subnet.webtier[count.index].id

  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.webtier_subnet_cidr)
  subnet_id      = aws_subnet.webtier[count.index].id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw[count.index].id
  }

  tags = {
    Name = "private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(var.apptier_subnet_cidr)
  subnet_id      = aws_subnet.apptier[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Fetch your current public IP
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

resource "aws_security_group" "internet_facing_load_balancer_sg" {
  name        = "internet-facing-lb-sg"
  description = "Allow inbound HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "internet-facing-lb-sg"
  }

}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "External access to web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"] # 👈 Only your IP
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.internet_facing_load_balancer_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"] # 👈 Only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "internal_load_balancer_sg" {
  name        = "internal-lb-sg"
  description = "Allow inbound HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "internal-lb-sg"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Access to application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_load_balancer_sg.id]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"] # 👈 Only your IP for testing purposes
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "app-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Access to mysql/aurora database servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "aurora-subnet-group"
  description = "Subnet group for Aurora MySQL cluster"
  subnet_ids  = aws_subnet.dbtier[*].id

  tags = {
    Name = "aurora-subnet-group"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier     = "aurora-mysql-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.05.2" # check latest supported
  database_name          = "mydb"
  master_username        = "admin"
  master_password        = "SuperSecret123!"
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  backup_retention_period = 7
  preferred_backup_window = "02:00-03:00"

  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count                = 2
  identifier           = "aurora-instance-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  tags = {
    Name = "aurora-instance-${count.index + 1}"
  }
}

resource "aws_s3_bucket" "code_storage" {
  bucket = "3tier-application-code-storage694" # Change to a globally unique name

  tags = {
    Name = "3tier-app-code-storage"
  }

}

resource "aws_iam_role" "ec2_full_access_role" {
  name = "ec2-full-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_vpc_s3_rds_full_access" {
  name        = "ec2-vpc-s3-rds-full-access"
  description = "Full access to EC2, VPC, S3, and RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "s3:*", "rds:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_full_access" {
  role       = aws_iam_role.ec2_full_access_role.name
  policy_arn = aws_iam_policy.ec2_vpc_s3_rds_full_access.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_full_access_role.name
}


# Launch Template for ASG
resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template-"
  image_id      = "ami-09a68c29a8b7a1586" # Custom AppTierImage with pre-configured app
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  key_name = "demo"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    aws s3 sync s3://3tier-application-code-storage694/app-tier/ /home/ec2-user/app/ --delete
    cd /home/ec2-user/app && npm install --production
    pm2 restart all || pm2 start index.js --name "app"
  EOF
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg"
  vpc_zone_identifier = aws_subnet.apptier[*].id
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  health_check_type   = "EC2"

  min_size         = 2
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-tier-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Application"
    propagate_at_launch = true
  }
}

# Target Group for App Tier
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-tg"
  }
}

# Internal Load Balancer (for app tier)
resource "aws_lb" "internal_lb" {
  name               = "app-tier-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_load_balancer_sg.id]
  subnets            = aws_subnet.apptier[*].id

  enable_deletion_protection = false

  tags = {
    Name = "internal-lb"
  }
}

# Listener for Internal Load Balancer
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


# Launch Template for Web Tier
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template-"
  image_id      = "ami-09ccd985141606aa9" # Custom WebTierImage with pre-configured app
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  key_name = "demo"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    aws s3 sync s3://3tier-application-code-storage694/web-tier/build/ /var/www/html/ --delete
    systemctl restart nginx
  EOF
  )
}

# Auto Scaling Group for Web Tier
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg"
  vpc_zone_identifier = aws_subnet.webtier[*].id
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  health_check_type   = "EC2"

  min_size         = 2
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-tier-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Web"
    propagate_at_launch = true
  }
}

# Listener for Internet-facing Load Balancer
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.internet_facing_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# HTTPS Listener for Internet-facing Load Balancer
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.internet_facing_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "arn:aws:acm:eu-north-1:857156722233:certificate/9326c6b7-089a-4936-9483-190fb8f76194"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


# Internet-facing Load Balancer (for web tier)
resource "aws_lb" "internet_facing_lb" {
  name               = "web-tier-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internet_facing_load_balancer_sg.id]
  subnets            = aws_subnet.webtier[*].id

  enable_deletion_protection = false

  tags = {
    Name = "internet-facing-lb"
  }
}

# Target Group for Web Tier
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-tg"
  }
}
