resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.alltag}-EKS-CLUSTER"
  role_arn = var.eks-cluster-role
  version  = "1.23"
  vpc_config {
    subnet_ids              = [var.subnet_id1, var.subnet_id2]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name  = "${var.alltag}-EKS-CLUSTER",
    Owner = "ksj"
  }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks-cluster.id}"
  }

}

