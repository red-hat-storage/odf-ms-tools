output "vpc_id" {
  value = data.aws_vpc.site.id
}

output "vpc_cidr" {
  value = data.aws_vpc.site.cidr_block
}

output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  value = sort(aws_network_interface.bastion.private_ips)[0]
}
