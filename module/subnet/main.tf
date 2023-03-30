resource "aws_subnet" "subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = var.is_public

  tags = {
    Name = "${var.alltag}-subnet-${var.public_or_private[var.is_public]}"
 Owner = "ksj"
  }
}
