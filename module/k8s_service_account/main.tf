resource "kubernetes_service_account" "service_account" {
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
