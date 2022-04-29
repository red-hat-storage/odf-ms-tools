resource "aws_vpc" "site" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.site_name
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.site.id
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.site.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "${var.region}a"
  tags = {
    Name = join("-", [var.site_name, "subnet", "public1", "${var.region}a"])
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.site.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "${var.region}b"
  tags = {
    Name = join("-", [var.site_name, "subnet", "public2", "${var.region}b"])
  }
}

resource "aws_subnet" "public3" {
  vpc_id            = aws_vpc.site.id
  cidr_block        = "10.0.32.0/20"
  availability_zone = "${var.region}c"
  tags = {
    Name = join("-", [var.site_name, "subnet", "public3", "${var.region}c"])
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.site.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "${var.region}a"
  tags = {
    Name = join("-", [var.site_name, "subnet", "private1", "${var.region}a"])
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.site.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "${var.region}b"
  tags = {
    Name = join("-", [var.site_name, "subnet", "private2", "${var.region}b"])
  }
}

resource "aws_subnet" "private3" {
  vpc_id            = aws_vpc.site.id
  cidr_block        = "10.0.160.0/20"
  availability_zone = "${var.region}c"
  tags = {
    Name = join("-", [var.site_name, "subnet", "private3", "${var.region}c"])
  }
}

#
# Internet gateway
#
resource "aws_internet_gateway" "site" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = join("-", [var.site_name, "igw"])
  }
}

#
# Elastic IPs for NAT gateways
#
resource "aws_eip" "nat1" {
  vpc = true
  tags = {
    Name = join("-", [var.site_name, "eip", "${var.region}a"])
  }
}

resource "aws_eip" "nat2" {
  vpc = true
  tags = {
    Name = join("-", [var.site_name, "eip", "${var.region}b"])
  }
}

resource "aws_eip" "nat3" {
  vpc = true
  tags = {
    Name = join("-", [var.site_name, "eip", "${var.region}c"])
  }
}

#
# NAT gateways
#
resource "aws_nat_gateway" "public1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = join("-", [var.site_name, "nat", "public1", "${var.region}a"])
  }
}

resource "aws_nat_gateway" "public2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public2.id

  tags = {
    Name = join("-", [var.site_name, "nat", "public2", "${var.region}b"])
  }
}

resource "aws_nat_gateway" "public3" {
  allocation_id = aws_eip.nat3.id
  subnet_id     = aws_subnet.public3.id

  tags = {
    Name = join("-", [var.site_name, "nat", "public3", "${var.region}c"])
  }
}

#
# Route tables
#
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = join("-", [var.site_name, "rtb", "public"])
  }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = join("-", [var.site_name, "rtb", "private1", "${var.region}a"])
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = join("-", [var.site_name, "rtb", "private2", "${var.region}b"])
  }
}

resource "aws_route_table" "private3" {
  vpc_id = aws_vpc.site.id
  tags = {
    Name = join("-", [var.site_name, "rtb", "private3", "${var.region}c"])
  }
}

#
# Routes
#
# Send all IPv4 traffic to the internet gateway
resource "aws_route" "ipv4_egress_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.site.id
  depends_on             = [aws_route_table.public]
}

# Send all IPv6 traffic to the internet gateway
resource "aws_route" "ipv6_egress_route" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.site.id
  depends_on                  = [aws_route_table.public]
}

# Send private traffic to NAT
resource "aws_route" "private1_nat" {
  route_table_id         = aws_route_table.private1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public1.id
  depends_on             = [aws_route_table.private1, aws_nat_gateway.public1]
}

resource "aws_route" "private2_nat" {
  route_table_id         = aws_route_table.private2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public2.id
  depends_on             = [aws_route_table.private2, aws_nat_gateway.public2]
}

resource "aws_route" "private3_nat" {
  route_table_id         = aws_route_table.private3.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public3.id
  depends_on             = [aws_route_table.private3, aws_nat_gateway.public3]
}

# Private route for vpc endpoint
resource "aws_vpc_endpoint_route_table_association" "private1" {
  route_table_id  = aws_route_table.private1.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "private2" {
  route_table_id  = aws_route_table.private2.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "private3" {
  route_table_id  = aws_route_table.private3.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

#
# Route table associations
#
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private3.id
}
