output "subnet_id" {
  #value = aws_subnet.subnet.id
  value = flatten([for subnet_info in values(aws_subnet.subnet) : subnet_info.id])
}

output "test" {
  value = flatten([for subnet_info in values(aws_subnet.subnet) : subnet_info.id])
}