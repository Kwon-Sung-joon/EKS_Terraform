resource "aws_eks_addon" "addon" {
  cluster_name                = var.eks_cluster_addon_config.name
  addon_name                  = var.eks_cluster_addon_config.addon_name
  addon_version               = var.eks_cluster_addon_config.addon_version
  resolve_conflicts_on_create = var.eks_cluster_addon_config.resolve_conflicts_on_create
  dynamic "configuration_values" {
    for_each = var.eks_cluster_addon_config.configuration_values
    content {
      configuration_values = configuration_values.value.configuration_value
    }
  }
}
