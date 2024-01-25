variable "vpc_id" {}
variable "public_subnet_cidr" {}
variable "public_subnet_az" {}
variable "alltag" {}
variable "is_public" {}

variable "public_or_private" {
  type = map(any)
  default = {
    true  = "public"
    false = "private"
  }
}
