
# Target Group for App Tier
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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
  security_groups    = [var.internal_load_balancer_sg]
  subnets            = var.apptier

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
#resource "aws_lb_listener" "https_listener" {
#  load_balancer_arn = aws_lb.internet_facing_lb.arn
#  port              = "443"
#  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  certificate_arn   = aws_acm_certificate.cert.arn

#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.web_tg.arn
#  }
#}

# Internet-facing Load Balancer (for web tier)
resource "aws_lb" "internet_facing_lb" {
  name               = "web-tier-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.internet_facing_load_balancer_sg]
  subnets            = var.webtier

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
  vpc_id   = var.vpc_id

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

