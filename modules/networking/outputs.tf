output "vpc_id"        { value = aws_vpc.main.id }
output "web_subnets"   { value = aws_subnet.webtier[*].id }
output "app_subnets"   { value = aws_subnet.apptier[*].id }
output "db_subnets"    { value = aws_subnet.dbtier[*].id }
