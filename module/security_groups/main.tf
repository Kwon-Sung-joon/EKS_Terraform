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
  for_each = var.sg_config.ingress
  cidr_ipv4   = each.value.cidr_ipv4
  from_port   = each.value.from_port
  ip_protocol = each.value.ip_protocol
  to_port     = each.value.to_port
  description = each.value.description
}
resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_security_group.sg.id
  for_each = var.sg_config.egress
  cidr_ipv4   = each.value.cidr_ipv4
  from_port   = each.value.from_port
  ip_protocol = each.value.ip_protocol
  to_port     = each.value.to_port
  description = each.value.description
}


