output "subnet_id" {
  #value = flatten([for subnet_info in values(aws_subnet.subnet) : subnet_info.id])

  value = [for key, subnet in aws_subnet.subnet : subnet.id]
}
