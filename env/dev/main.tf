module "vpc" {
  source   = "../../module/vpc"
  vpc_cidr = var.vpc_cidr
  alltag   = var.alltag
}
/*
module "nat_gw" {
  source        = "../../module/nat"
  alltag        = var.alltag
  public_subnet = module.public_subnet1.subnet_id
  depends_on    = [module.vpc, module.public_subnet1]
}
*/
module "pub_subnets" {
  source = "../../module/subnets"
  for_each = merge(var.subnets,local.pub_subnets)
  subnet_config=each.value
}
module "pri_subnets" {
  source = "../../module/subnets"
  for_each = merge(var.subnets,local.pri_subnets)
  subnet_config=each.value
}
output "pub_subnet_ids" {
  value = flatten([for subnet_info in values(module.pub_subnets) : subnet_info.subnet_id])
}
output "pri_subnet_ids" {
  value = flatten([for subnet_info in values(module.pri_subnets) : subnet_info.subnet_id])
}
module "public_subnet_rtb_igw" {
  source     = "../../module/rtb_igw"
  vpc_id     = module.vpc.vpc_id
  igw_id     = module.vpc.igw_id
  subnet_ids = flatten([for subnet_info in values(module.pub_subnets) : subnet_info.subnet_id])
  alltag     = var.alltag
}
/*
module "private_subnet_rtb_nat" {
  source     = "../../module/rtb_nat"
  vpc_id     = module.vpc.vpc_id
  nat_gw_id  = module.nat_gw.nat_gw
  subnet_ids = flatten([for subnet_info in values(module.pri_subnets) : subnet_info.subnet_id])
  alltag     = var.alltag
}
module "eks_node_groups" {
  source       = "../../module/eks_node_groups"
  alltag       = var.alltag
  cluster_name = module.eks_cluster.cluster_name
  subnet_ids        = [module.private_subnet1.subnet_id,module.private_subnet2.subnet_id]
 // node_types   = var.node_types
  depends_on = [
    module.eks_node_group_iam_role
  ]
  eks-ng-role = module.eks_node_group_iam_role.iam_role
  desired     = 1
  max         = 4
  min = 0
  lt_id = module.eks_node_lt.id
}
*/
/*
module "eks_cluster" {
  source            = "../../module/eks_cluster"
  subnet_ids        = flatten([for subnet_info in values(module.pub_subnets) : subnet_info.subnet_id])
  alltag            = var.alltag
  service_ipv4_cidr = var.eks_cluster_service_ipv4_cidr
  depends_on = [
    module.eks_cluster_iam_role
  ]
  eks-cluster-role    = module.eks_cluster_iam_role["dev_cluster"].iam_role
  eks-cluster-version = 1.26
  vpc_cidr = var.vpc_cidr
}
*/
module "eks_cluster_iam_role" {
  source             = "../../module/iam_role"
  #for_each = merge(var.iam_roles,local.EKS_CLUSTER_ROLE)
  for_each = merge(var.iam_roles,local.EKS_CLUSTER_ROLE)
  iam_role_config = each.value
}
output eks_cluster_role {
  value = flatten([for iam_roles in module.eks_cluster_iam_role : iam_roles.iam_role])
}
module "eks_node_group_iam_role" {
  source             = "../../module/iam_role"
  for_each = merge(var.iam_roles,local.EKS_NODE_GROUP_ROLE)
  iam_role_config = each.value
}
output eks_node_group_role {
  value = flatten([for iam_roles in module.eks_node_group_iam_role : iam_roles.iam_role])
}

output eks_node_group_role2 {
  value = module.pub_subnets["pub_subnets"]["pub1"].subnet_id
}
/*
module "eks_node_lt" {
  source      = "../../module/launch_template"
  lt_ec2_type = "t3.medium"
  lt_image_id = "ami-06aaf7c21e7e74e2a"
  lt_name     = "${var.alltag}-eks-ng-lt"
  user_data = base64encode(templatefile("${path.module}/user_data/eks_node.sh", { CLUSTER-NAME = module.eks_cluster.cluster_name,
    B64-CLUSTER-CA     = module.eks_cluster.kubeconfig-certificate-authority-data,
    APISERVER-ENDPOINT = module.eks_cluster.endpoint,
    DNS-CLUSTER-IP = cidrhost(var.eks_cluster_service_ipv4_cidr, 10) }))
  vpc_security_group_ids = [module.eks_node_sg.id]
  depends_on             = [module.eks_cluster, module.eks_node_sg]
}

module "eks_node_sg" {
  source = "../../module/sg"
  alltag  = "ksj-eks-node"
  sg_desc = "ksj-eks-node-sg"
  sg_name = "ksj-eks-node-sg"
  vpc_id  = module.vpc.vpc_id
  depends_on = [module.vpc]
}

/*
module "ecr_repos" {
  source         = "../../module/ecr"
  ecr-repos-name = var.ecr-repose-name
}

module "bastion" {
  source       = "../../module/bastion"
  alltag       = var.alltag
  subnet_id1   = module.public_subnet1.subnet_id
  ami_id       = var.bastionAmi
  keypair_name = var.bastionKey
  vpc_id       = module.vpc.vpc_id
  user_data    = "./user_data/install_docker.sh"
}
*/