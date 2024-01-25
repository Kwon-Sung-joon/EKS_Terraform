resource "aws_eks_node_group" "eks-node-group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.alltag}-eks-node-groups"
  node_role_arn   = var.eks-ng-role

  subnet_ids      = var.subnet_ids
  scaling_config {
    desired_size = var.desired
    max_size     = var.max
    min_size     = var.min
  }
  launch_template {
    version = "$Latest"
    id = var.lt_id
  }
//  instance_types = [var.node_types]

  tags = {
    Name = "${var.alltag}-eks-managed-node-group"
    Owner = "ksj"
  }
}

