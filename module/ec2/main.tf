resource "aws_iam_instance_profile" "instance_profile" {
  name = var.ec2_instance_config.instance_profile_name
  role = var.ec2_instance_config.iam_role
}


resource "aws_instance" "instance" {
  ami                    = var.ec2_instance_config.ami
  instance_type          = var.ec2_instance_config.instance_type
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = var.ec2_instance_config.vpc_security_group_ids
  subnet_id              = var.ec2_instance_config.subnet_id
  user_data              = var.ec2_instance_config.user_data
  tags = var.ec2_instance_config.tags
}



output "private_ip" {
  value = aws_instance.instance.private_ip
}
