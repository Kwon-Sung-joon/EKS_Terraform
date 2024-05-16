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

  provisioner "local-exec" {
    command = <<-EOT
sed -i -e 's|<ARN of nodegroup role>|${var.eks_cluster_config.node_group_role}|' ${path.root}/manifest/aws-auth.yaml
sed -i -e 's|<ARN of admin role>|${var.eks_cluster_config.admin_role}|' ${path.root}/manifest/aws-auth.yaml
cat ${path.root}/manifest/aws-auth.yaml
aws eks update-kubeconfig --region ap-northeast-2 --name ${var.eks_cluster_config.name}
kubectl apply -f ${path.root}/manifest/aws-auth.yaml
aws s3 cp ~/.kube/config ${var.eks_cluster_config.upload_kubeconfig}
EOT
    }
}
