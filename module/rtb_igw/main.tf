resource "aws_route_table" "rtb" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.alltag}-rtb-public"
Owner = "ksj"
  }
  route {
	cidr_block = "0.0.0.0/0"
  	gateway_id             = var.igw_id
  }

}

resource "aws_route_table_association" "rtb" {

  count = length(var.subnet_ids)
  subnet_id      = var.subnet_ids[count.index]
  route_table_id = aws_route_table.rtb.id
}



