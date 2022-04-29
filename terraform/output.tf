output "vpc_id" {
  value = aws_vpc.site.id
}
output "subnet_public1_id" {
  value = aws_subnet.public1.id
}
output "subnet_public2_id" {
  value = aws_subnet.public2.id
}
output "subnet_public3_id" {
  value = aws_subnet.public3.id
}
output "subnet_private1_id" {
  value = aws_subnet.private1.id
}
output "subnet_private2_id" {
  value = aws_subnet.private2.id
}
output "subnet_private3_id" {
  value = aws_subnet.private3.id
}
