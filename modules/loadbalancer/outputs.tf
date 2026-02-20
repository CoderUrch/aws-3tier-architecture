output "web_tg" {
  description = "Target group for the web tier"
  value       = aws_lb_target_group.web_tg.arn
}

output "app_tg" {
  description = "Target group for the app tier"
  value       = aws_lb_target_group.app_tg.arn
}