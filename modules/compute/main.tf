# Launch Template for ASG
resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template-"
  image_id      = "ami-0ec9b860c84acaffc" # Custom AppTierImage with pre-configured app
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
  target_group_arns   = [var.app_tg]  # Use the new variable for the ARN
  health_check_type   = "ELB"

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
  image_id      = "ami-0cb230df875b17a25" # Custom WebTierImage with pre-configured app
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
  health_check_type   = "ELB"

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

resource "aws_instance" "app_instance" {
  ami           = "ami-073130f74f5ffb161"
  instance_type = "t3.micro"
  subnet_id     = var.apptier[0]
  key_name      = "aws-ssh"

  vpc_security_group_ids = [var.app_sg]
  iam_instance_profile   = var.ec2_instance_profile

  tags = {
    Name = "app-test-vm"
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-073130f74f5ffb161"
  instance_type = "t3.micro"
  subnet_id     = var.webtier[0]
  key_name      = "aws-ssh"

  vpc_security_group_ids = [var.web_sg]
  iam_instance_profile   = var.ec2_instance_profile

  tags = {
    Name = "web-test-vm"
  }
}