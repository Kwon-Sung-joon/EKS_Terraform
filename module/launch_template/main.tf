resource "aws_launch_template" "ec2_lt" {
  name = "${var.lt_name}"
  image_id = "${var.lt_image_id}"
  instance_type = "${var.lt_ec2_type}"
  count = length(var.vpc_security_group_ids)
  vpc_security_group_ids      = var.vpc_security_group_ids[count.index]
  user_data              = var.user_data
}