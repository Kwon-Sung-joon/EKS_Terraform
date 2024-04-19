resource "aws_security_group" "sg" {
  name        = var.sg_config.name
  description = var.sg_config.description
  vpc_id      = var.sg_config.vpc_id
  tags = {
    Name = "${var.sg_config.alltag}-sg"

    Owner = "ksj"
  }
}
output "id" {
  value = aws_security_group.sg.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4   = "10.0.0.0/8"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}
resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4   = "10.0.0.0/8"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}


