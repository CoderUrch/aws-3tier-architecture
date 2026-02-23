resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
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