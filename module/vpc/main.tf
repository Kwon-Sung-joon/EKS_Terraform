resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_config.vpc_cidr
  enable_dns_hostnames = true

  tags = var.vpc_config.tags
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = var.vpc_config.tags

  provisioner "local-exec" {
    command = <<-EOT
cat ${path.root}/env/dev/manifest/aws-auth.yaml"
EOT
  }
}

