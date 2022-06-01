variable "site_name" {
  description = "The name of the test site."
  type        = string
}

variable "subnet_count" {
  description = "The number of public/private subnet pairs to make."
  type        = number
}

variable "vpc_cidr" {
  description = "The CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [data.aws_region.current.name]
  }
}
