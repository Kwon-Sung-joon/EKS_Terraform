output "endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}
output "cluster_name" {
  value = aws_eks_cluster.eks-cluster.id
}
output "cluster_sg_id" {
  value = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc" {
  value = aws_eks_cluster.eks-cluster.identity
}