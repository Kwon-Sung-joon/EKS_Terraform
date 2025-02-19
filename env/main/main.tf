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
  depends_on = [module.vpc]
}
output "subnets" {
  value = flatten([for subnet_info in values(module.subnets) : subnet_info.subnet_id])
}
module "route_tables" {
  source     = "../../module/route_table"
  for_each = merge(var.route_tables,local.DEV_ROUTE_TABLE)
  route_table_config = each.value
  #depends_on = [module.vpc, module.nat_gw,module.subnets]
  depends_on = [module.vpc, module.subnets]
}
module "iam_role" {
  source             = "../../module/iam_role"
  #for_each = merge(var.iam_roles,local.EKS_CLUSTER_ROLE)
  for_each = merge(var.iam_roles,local.DEV_IAM_ROLE)
  iam_role_config = each.value
  depends_on = [module.iam_policy]
}
output iam_role {
  value = flatten([for iam_roles in module.iam_role : iam_roles.iam_role])
}
module "iam_policy" {
  source = "../../module/iam_policy"
  for_each = merge(var.iam_policies,local.DEV_IAM_POLICY)
  iam_policy_config = each.value
}
output iam_policy {
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
    module.iam_role,
    module.security_groups,
    module.subnets
  ]
}

output eks_oidc {
  value = module.eks_cluster["dev_cluster_1"].cluster_oidc
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
  depends_on = [module.launch_template, module.iam_role,module.subnets,module.eks_cluster]
}

module "ec2_instance" {
  source = "../../module/ec2"
  for_each = merge(var.ec2_instance,local.DEV_EC2_INSTANCE)
  ec2_instance_config = each.value
  depends_on = [module.security_groups,
    module.iam_role,
    module.eks_cluster,
    module.subnets
  ]
}

module "iam_oidc" {
  source = "../../module/iam_oidc"
  for_each = merge(var.iam_oidc,local.DEV_IAM_OIDC)
  iam_oidc_config = each.value
  depends_on = [
  module.eks_cluster]
}


module "iam_irsa" {
  source = "../../module/iam_role"
  for_each = merge(var.iam_roles,local.DEV_IAM_ROLE_IRSA)
  iam_role_config = each.value
  depends_on = [
  module.eks_cluster,module.iam_oidc]
}

output iam_irsa {
  value = flatten([for iam_roles in module.iam_irsa : iam_roles.iam_role])
}

module "k8s_karpenter" {
  source = "../../module/karpenter"
  for_each = merge(var.k8s_karpenter,local.DEV_KARPENTER)
  karpenter_config = each.value
}

module "helm_release" {
  source = "../../module/helm"
  for_each = merge(var.helm_release,local.DEV_HELM)
  helm_release_config = each.value
  depends_on = [module.k8s_karpenter]
}
/*
## it takes 15 minutes to create addon
module "eks_cluster_addons" {
  source = "../../module/eks_cluster_add_on"
  for_each = merge(var.dev_eks_cluster_addons,local.DEV_EKS_CLUSTER_ADDONS)
  eks_cluster_addon_config = each.value
}


*/

##K8S Resources
module "k8s_manifest" {
  source = "../../module/k8s_manifest"
  for_each = merge(var.k8s_manifest,local.DEV_K8S_MANIFEST)
  k8s_manifest_config = each.value
  #depends_on = [module.helm_release]
}
