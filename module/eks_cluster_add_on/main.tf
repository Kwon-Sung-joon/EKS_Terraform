resource "aws_eks_addon" "addon" {
  cluster_name                = var.eks_cluster_addon_config.cluster_name
  addon_name                  = var.eks_cluster_addon_config.addon_name
  addon_version               = var.eks_cluster_addon_config.addon_version
  resolve_conflicts_on_create = var.eks_cluster_addon_config.resolve_conflicts_on_create
  resolve_conflicts_on_update = var.eks_cluster_addon_config.resolve_conflicts_on_update
}
