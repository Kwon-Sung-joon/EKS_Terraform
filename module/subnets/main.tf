resource "aws_subnet" "subnet" {
  vpc_id                  = var.subnet_config.vpc_id
  cidr_block              = var.subnet_config.subnet_cidr
  availability_zone       = var.subnet_config.subnet_az
  map_public_ip_on_launch = var.subnet_config.is_public
  tags = var.subnet_config.tags
}
