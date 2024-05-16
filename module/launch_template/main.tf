resource "aws_launch_template" "ec2_lt" {
  name = var.launch_template_config.name
  image_id = var.launch_template_config.image_id
  instance_type = var.launch_template_config.instance_type
  vpc_security_group_ids      = var.launch_template_config.vpc_security_group_ids
  user_data              = var.launch_template_config.user_data
  update_default_version = var.launch_template_config.update_default_version
}

output "id" {
  value = aws_launch_template.ec2_lt.id
}