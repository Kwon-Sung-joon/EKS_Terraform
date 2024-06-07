resource "helm_release" "release" {
  repository = var.helm_release_config.repository
  chart = var.helm_release_config.chart
  name  = var.helm_release_config.name
  dynamic "set" {
    for_each = var.helm_release_config.set
    content {
      name = set.value.name
      value = set.value.value
    }
  }
  create_namespace=var.helm_release_config.create_namespace
}