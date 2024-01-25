resource "aws_eks_node_group" "eks-node-group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.alltag}-eks-node-groups"
  node_role_arn   = var.eks-ng-role
  subnet_ids      = [var.subnet_id1, var.subnet_id2]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = [var.node_types]

  tags = {
    Name = "${var.alltag}-eks-managed-node-group"
    Owner = "ksj"
  }
}

