resource "aws_route_table" "rtb_nat" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.nat_gw_id
  }

tags = {
    Name = "${var.alltag}-rtb-private-nat"
Owner = "ksj"
  }
}

resource "aws_route_table_association" "rtb" {
  count = length(var.subnet_ids)
  subnet_id      = var.subnet_ids[count.index]
  route_table_id = aws_route_table.rtb_nat.id
}