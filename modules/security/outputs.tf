output "internet_facing_load_balancer_sg" {
  value = aws_security_group.internet_facing_load_balancer_sg.id
}

output "internal_load_balancer_sg" {
  value = aws_security_group.internal_load_balancer_sg.id
}

output "db_sg" {
  value = aws_security_group.db_sg.id
}

output "web_sg" {
  value = aws_security_group.web_sg.id
}

output "app_sg" {
  value = aws_security_group.app_sg.id
} 
