resource "aws_route_table" "rtb" {
  vpc_id = var.route_table_config.vpc_id
  tags = var.route_table_config.tags
  dynamic "route" {
    for_each = var.route_table_config.route
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.gateway_id
    }
  }
}
resource "aws_route_table_association" "rtb" {
  count = length(var.route_table_config.subnets)
  subnet_id      = var.route_table_config.subnets[count.index]
  route_table_id = aws_route_table.rtb.id
}