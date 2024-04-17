#output "subnet_id" {
#  value = aws_subnet.subnet.id
#}

output "subnet_id" {
  value = flatten([for subnet in values(aws_subnet.subnet) : subnet.id])
}
