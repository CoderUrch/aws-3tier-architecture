# Launch Template for ASG
resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template-"
  image_id      = "ami-0a716d3f3b16d290c" # Custom AppTierImage with pre-configured app
  instance_type = "t3.micro"

  vpc_security_group_ids = [var.app_sg]
  iam_instance_profile {
    name = var.ec2_instance_profile
  }

}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg"
  vpc_zone_identifier = var.apptier
  target_group_arns   = [var.app_tg]
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



# Launch Template for Web Tier
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template-"
  image_id      = "ami-0a716d3f3b16d290c" # Custom WebTierImage with pre-configured app
  instance_type = "t3.micro"

  vpc_security_group_ids = [var.web_sg]
  iam_instance_profile {
    name = var.ec2_instance_profile
  }

}

# Auto Scaling Group for Web Tier
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg"
  vpc_zone_identifier = var.webtier
  target_group_arns   = [var.web_tg]
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
