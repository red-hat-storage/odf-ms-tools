resource "aws_security_group" "ping_ssh" {
  name        = "ping_ssh"
  description = "allow ICMP and SSH traffic"
  vpc_id      = data.aws_vpc.site.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "icmp"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "local_file" "ssh_key_file" {
  filename = var.key_file
}

resource "aws_key_pair" "ssh_client" {
  public_key = data.local_file.ssh_key_file.content
  tags = {
    Owner = "rcampos"
  }
}
