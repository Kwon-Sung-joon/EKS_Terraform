variable "lt_name" {}
variable "lt_image_id" {}
variable "lt_ec2_type" {}
variable "vpc_security_group_ids" {
  type = list(string)
}
variable "user_data" {}
