resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.nat_config.public_subnet
tags = {
    Name = "${var.nat_config.alltag}-nat",
    Owner = "ksj"
  }
  depends_on = [aws_eip.nat_eip]
}

output "nat_gw" {
  value = aws_nat_gateway.nat_gw.id
}