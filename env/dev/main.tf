
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


module "subnets" {
  source = "../../module/subnets"
  for_each = merge(var.subnets,local.subnets)
  subnet_config=each.value
}
output "subent_ids1" {
  value = {
    for k, subnet in module.subnets : k => subnet.subnet_id
  }
}
output "subnet_ids" {
  value = module.subnets.subnet_id
}
/*
module "public_subnet1" {
  source             = "../../module/subnet"
  vpc_id             = module.vpc.vpc_id
  public_subnet_cidr = var.public_subnet1_cidr
  public_subnet_az   = data.aws_availability_zones.available.names["${var.public_subnet1_az}"]
  is_public          = true
  alltag             = var.alltag
}
module "public_subnet2" {
  source = "../../module/subnet"

  vpc_id             = module.vpc.vpc_id
  public_subnet_cidr = var.public_subnet2_cidr
  public_subnet_az   = data.aws_availability_zones.available.names["${var.public_subnet2_az}"]
  is_public          = true
  alltag             = var.alltag
}
module "private_subnet1" {
  source = "../../module/subnet"

  vpc_id             = module.vpc.vpc_id
  public_subnet_cidr = var.private_subnet1_cidr
  public_subnet_az   = data.aws_availability_zones.available.names["${var.private_subnet1_az}"]
  is_public          = false
  alltag             = var.alltag
}
module "private_subnet2" {
  source = "../../module/subnet"

  vpc_id             = module.vpc.vpc_id
  public_subnet_cidr = var.private_subnet2_cidr
  public_subnet_az   = data.aws_availability_zones.available.names["${var.private_subnet2_az}"]
  is_public          = false
  alltag             = var.alltag
}
*/
/*
module "public_subnet_rtb_igw" {
  source     = "../../module/rtb_igw"
  vpc_id     = module.vpc.vpc_id
  igw_id     = module.vpc.igw_id
  subnet_ids = [module.subnets.subnet_id]
  alltag     = var.alltag
}
*/
/*
module "private_subnet_rtb_nat" {
  source     = "../../module/rtb_nat"
  vpc_id     = module.vpc.vpc_id
  nat_gw_id  = module.nat_gw.nat_gw
  subnet_ids = [module.private_subnet1.subnet_id, module.private_subnet2.subnet_id]
  alltag     = var.alltag
}
module "eks_cluster" {
  source            = "../../module/eks_cluster"
  subnet_ids        = [module.public_subnet1.subnet_id,
    module.public_subnet2.subnet_id,
    module.private_subnet1.subnet_id,
    module.private_subnet2.subnet_id]
  alltag            = var.alltag
  service_ipv4_cidr = var.eks_cluster_service_ipv4_cidr
  depends_on = [
    module.eks_cluster_iam_role
  ]
  eks-cluster-role    = module.eks_cluster_iam_role.iam_role
  eks-cluster-version = 1.26
  vpc_cidr = var.vpc_cidr
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

module "eks_cluster_iam_role" {
  source             = "../../module/iam_role"
  name               = "${var.alltag}-eks-cluster-role"
  tag_name           = "${var.alltag}-IAM-ROLE-EKS-CLUSTER"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_role.json
  mgd_policies       = var.mgd_policies_for_eks_cluster

}
module "eks_node_group_iam_role" {
  source             = "../../module/iam_role"
  name               = "${var.alltag}-eks-nodegroup-role"
  tag_name           = "${var.alltag}-IAM-ROLE-EKS-NODEGROUP"
  assume_role_policy = data.aws_iam_policy_document.eks_node_group_role.json
  mgd_policies       = var.mgd_policies_for_eks_node_group
}
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
*/

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