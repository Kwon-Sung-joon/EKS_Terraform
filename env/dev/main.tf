
resource "aws_iam_role" "test" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_role.json
  provisioner "local-exec" {
    command = "ls"
  }
}
module "vpc" {
  source   = "../../module/vpc"
  for_each = merge(var.vpc_cidr,local.DEV_VPC)
  vpc_config=each.value

}
module "nat_gw" {
  source        = "../../module/nat"
  for_each = merge(var.nat_gw,local.DEV_NAT_GW)
  nat_config=each.value
  depends_on    = [module.vpc, module.subnets]
}
module "subnets" {
  source = "../../module/subnets"
  for_each = merge(var.subnets,local.DEV_SUBNETS)
  subnet_config=each.value
}


output "subnets" {
  value = flatten([for subnet_info in values(module.subnets) : subnet_info.subnet_id])
}

module "route_tables" {
  source     = "../../module/route_table"
  for_each = merge(var.route_tables,local.DEV_ROUTE_TABLE)
  route_table_config = each.value
  depends_on = [module.vpc, module.nat_gw,module.subnets]
}
module "iam_role" {
  source             = "../../module/iam_role"
  #for_each = merge(var.iam_roles,local.EKS_CLUSTER_ROLE)
  for_each = merge(var.iam_roles,local.DEV_IAM_ROLE)
  iam_role_config = each.value
}
output iam_role {
  value = flatten([for iam_roles in module.iam_role : iam_roles.iam_role])
}

module "security_groups" {
  source = "../../module/security_groups"
  for_each = merge(var.security_group,local.DEV_SECURITY_GROUPS)
  sg_config = each.value
  depends_on = [module.vpc]
}
output eks_node_sg_id {
  value = module.security_groups["dev_eks_node_sg"].id
}

module "eks_cluster" {
  source            = "../../module/eks_cluster"
  for_each = merge(var.eks_cluster,local.DEV_EKS_CLUSTER)
  eks_cluster_config = each.value
  depends_on = [
    module.iam_role
  ]
}

module "launch_template" {
  source = "../../module/launch_template"
  for_each = merge(var.launch_template,local.DEV_LAUNCH_TEMPLATES)
  launch_template_config = each.value
  depends_on = [
  module.eks_cluster,module.security_groups
  ]
}

module "eks_node_group" {
  source = "../../module/eks_node_groups"
  for_each = merge(var.eks_node_group,local.DEV_EKS_NODE_GROUP)
  eks_node_group_config = each.value
  depends_on = [module.launch_template, module.iam_role]
}

module "ec2_instance" {
  source = "../../module/ec2"
  for_each = merge(var.ec2_instance,local.DEV_EC2_INSTANCE)
  ec2_instance_config = each.value
  depends_on = [module.security_groups, module.iam_role,module.eks_cluster]
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
