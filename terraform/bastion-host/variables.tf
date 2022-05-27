variable "vpc_id" {
  description = "Enter the id of the VPC to deploy the bastion host:"
  type        = string
}

variable "key_file" {
  description = "The key file used to ssh into probes"
  type        = string
}
