variable "subnet_config" {}
variable "public_or_private" {
  type = map(any)
  default = {
    true  = "public"
    false = "private"
  }
}