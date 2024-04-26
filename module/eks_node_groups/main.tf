resource "aws_eks_node_group" "eks-node-group" {
  cluster_name    = var.eks_node_group_config.cluster_name
  node_group_name = var.eks_node_group_config.node_group_name
  node_role_arn   = var.eks_node_group_config.node_role_arn
  subnet_ids      = var.eks_node_group_config.subnet_ids

  dynamic "scaling_config" {
    for_each = var.eks_node_group_config.scaling_config
    content {
      desired_size = scaling_config.value.desired_size
      max_size     = scaling_config.value.max_size
      min_size     = scaling_config.value.min_size
    }
  }

  dynamic "launch_template" {
    for_each = var.eks_node_group_config.launch_template
    content {
      version = launch_template.value.version
      id     = launch_template.value.id

    }
  }
  tags = var.eks_node_group_config.tags
}

