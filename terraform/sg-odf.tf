resource "aws_security_group" "odf_sg" {
  name        = "odf-sec-group"
  vpc_id      = aws_vpc.site.id
  description = "ODF Security Group"

  tags = {
    Name = "odf-sec-group"
  }

  timeouts {
    create = "20m"
  }
}

resource "aws_security_group_rule" "odf_egress" {
  type              = "egress"
  security_group_id = aws_security_group.odf_sg.id
  description       = "default"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
} 

resource "aws_security_group_rule" "odf_ingres_mon1" {
  type              = "ingress"
  security_group_id = aws_security_group.odf_sg.id
  description       = "ODF Ceph Mon v1"

  from_port = 6789
  to_port   = 6789
  protocol  = "tcp"
  cidr_blocks = [var.vpc_cidr]
}


resource "aws_security_group_rule" "odf_ingres_mon2" {
  type              = "ingress"
  security_group_id = aws_security_group.odf_sg.id
  description       = "ODF Ceph Mon v2"

  from_port = 3300
  to_port   = 3300
  protocol  = "tcp"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_security_group_rule" "odf_ingres_osd" {
  type              = "ingress"
  security_group_id = aws_security_group.odf_sg.id
  description       = "ODF Ceph OSD"

  from_port = 6800
  to_port   = 7300
  protocol  = "tcp"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_security_group_rule" "odf_ingres_mgr" {
  type              = "ingress"
  security_group_id = aws_security_group.odf_sg.id
  description       = "ODF Ceph Mgr"

  from_port = 9283
  to_port   = 9283
  protocol  = "tcp"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_security_group_rule" "odf_ingres_pro_api" {
  type              = "ingress"
  security_group_id = aws_security_group.odf_sg.id
  description       = "ODF Provider API"

  from_port = 31659
  to_port   = 31659
  protocol  = "tcp"
  cidr_blocks = [var.vpc_cidr]
}
