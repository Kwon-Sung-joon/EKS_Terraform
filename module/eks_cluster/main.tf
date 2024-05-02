resource "aws_eks_cluster" "eks-cluster" {
  name     = var.eks_cluster_config.name
  role_arn = var.eks_cluster_config.cluster_role
  version  = var.eks_cluster_config.cluster_version

  vpc_config {
    subnet_ids              = var.eks_cluster_config.subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = var.eks_cluster_config.sg_ids
  }
  kubernetes_network_config {
    service_ipv4_cidr = var.eks_cluster_config.service_ipv4_cidr
  }
  tags = var.eks_cluster_config.tags

/*
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks-cluster.id}"
  }
  */
}
