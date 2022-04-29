variable "region" {
  description = "Region for shared VPC"
  type        = string
}

variable "site_name" {
  description = "The name of the test site."
  type        = string
}

variable "vpc_cidr" {
  description = "The vpc cidr block, in x.x.x.x/16 format"
  type        = string
  default     = "10.0.0.0/16"
}

variable "sub_cidr" {
  description = "The subnet where the nodes will be deployed. x.y.0.0/20 format"
  type        = string
  default     = "10.0.0.0/20"
}

variable "az" {
  description = "The availability zone where the resources will be deployed"
  type        = string
  default     = "us-east-1a"
}
