output "aurora_cluster_endpoint" {
  description = "The writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "The reader endpoint for the Aurora cluster (load-balanced read replicas)"
  value       = aws_rds_cluster.aurora_cluster.reader_endpoint
}

# Essential - Application Access
output "application_url" {
  description = "Public URL to access the application"
  value       = "http://${aws_lb.internet_facing_lb.dns_name}"
}

output "internet_facing_lb_dns" {
  description = "DNS name of the internet-facing load balancer"
  value       = aws_lb.internet_facing_lb.dns_name
}

# Essential - Internal Communication
output "internal_lb_dns" {
  description = "Internal load balancer DNS (for nginx.conf configuration)"
  value       = aws_lb.internal_lb.dns_name
}

# Useful - Infrastructure IDs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for application code"
  value       = aws_s3_bucket.code_storage.bucket
}

# Useful - Networking
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.webtier[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.apptier[*].id
}

# Useful - Security
output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = aws_eip.elastic_ip[*].public_ip
}