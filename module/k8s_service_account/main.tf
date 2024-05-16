resource "aws_launch_template" "ec2_lt" {
  dynamic "metadata" {
    for_each = var.k8s_service_account_config.metadata
    content {
      name = metadata.value.name
      namespace = metadata.value.namespace
      labels = metadata.value.labels
      annotations = metadata.value.annotations
    }
  }
}

output "id" {
  value = aws_launch_template.ec2_lt.id
}