resource "aws_security_group" "sg" {
  name        = var.sg_name
  description = var.sg_desc
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.alltag}-sg"
    Owner = "ksj"
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
output "id" {
  value = aws_security_group.sg.id
}