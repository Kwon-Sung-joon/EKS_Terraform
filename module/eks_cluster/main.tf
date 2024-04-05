resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.alltag}-EKS-CLUSTER"
  role_arn = var.eks-cluster-role
  version  = var.eks-cluster-version
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }
  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }
  tags = {
    Name  = "${var.alltag}-EKS-CLUSTER",
    Owner = "ksj"
  }
/*
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks-cluster.id}"
  }
*/
}

resource "aws_security_group_rule" "eks-cluster-sg" {
  security_group_id = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  depends_on = [aws_eks_cluster.eks-cluster]
}


