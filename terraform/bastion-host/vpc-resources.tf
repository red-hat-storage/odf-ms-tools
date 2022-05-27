data "aws_vpc" "site" {
  id = var.vpc_id
}

data "aws_internet_gateway" "site" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "site" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.site.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_subnet" "site" {
  id = element(data.aws_subnets.site.ids, 0)
}

# resource "aws_route_table" "site" {
#   vpc_id = data.aws_vpc.site.id
# }
#data "aws_route_table" "site" {
#  subnet_id = data.aws_subnet.site.id
#}

# Send all IPv4 traffic to the internet gateway
#resource "aws_route" "ipv4_egress_route" {
#  route_table_id         = data.aws_route_table.site.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = data.aws_internet_gateway.site.id
#  depends_on             = [data.aws_route_table.site]
#}
#
## Send all IPv6 traffic to the internet gateway
#data "aws_route" "ipv6_egress_route" {
#  route_table_id              = data.aws_route_table.site.id
#  destination_ipv6_cidr_block = "::/0"
#  gateway_id                  = data.aws_internet_gateway.site.id
#  depends_on                  = [data.aws_route_table.site]
#}

# resource "aws_route_table_association" "site" {
#   subnet_id      = data.aws_subnet.site.id
#   route_table_id = data.aws_route_table.site.id
# }
