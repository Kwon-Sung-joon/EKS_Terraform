variable "vpc_cidr" {
  description = "VPC CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.0.0/16"
}
variable "alltag" {
  description = "name"
  default = "test"
}
variable "subnets" {
  type=map(object({
    vpc_id=any
    subnet_cidr=any
    subnet_az=any
    is_public=bool
    alltag=any
  }))
  default = {}
}
locals {
  pub_subnets= {
    pub1 = {
      vpc_id      = module.vpc.vpc_id
      subnet_cidr = "192.168.0.0/24"
      subnet_az   = data.aws_availability_zones.available.names[0]
      is_public   = true
      alltag      = "pub1"
    }
    pub2 = {
      vpc_id      = module.vpc.vpc_id
      subnet_cidr = "192.168.1.0/24"
      subnet_az   = data.aws_availability_zones.available.names[2]
      is_public   = true
      alltag      = "pub2"
    }
  }
  pri_subnets= {
    pri1 = {
      vpc_id      = module.vpc.vpc_id
      subnet_cidr = "192.168.2.0/24"
      subnet_az   = data.aws_availability_zones.available.names[1]
      is_public   = false
      alltag      = "pri1"
    }
    pri2 = {
      vpc_id      = module.vpc.vpc_id
      subnet_cidr = "192.168.3.0/24"
      subnet_az   = data.aws_availability_zones.available.names[3]
      is_public   = false
      alltag      = "pri2"
    }
  }
}
variable "iam_roles"{
  type=map(object({
    name=any
    tag_name=any
    assume_role_policy = any
    mgd_policies = set(string)
  }))
  default = {}
  }
locals {
  EKS_CLUSTER_ROLE = {
    dev_cluster = {
      name               = "dev_cluster_role"
      tag_name           = "dev_cluster_role"
      assume_role_policy = data.aws_iam_policy_document.eks_cluster_role.json
      mgd_policies       = toset([
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      ])
    }
  }
  EKS_NODE_GROUP_ROLE = {
    dev_node_group = {
      name               = "dev_node_group_role"
      tag_name           = "dev_node_group_role"
      assume_role_policy = data.aws_iam_policy_document.eks_node_group_role.json
      mgd_policies       = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
      ])
    }
  }
}
  /*
  variable "ecr-repose-name" {
    description = "ECR Repository Name"

  }

  variable "bastionAmi" {
    description = "Bastion AMI"
    default     = "ami-0cbec04a61be382d9"
  }
  variable "bastionKey" {
    description = "Bastion Key Paire what you have."
    default     = "TerraformTest"
  }
  */


variable "node_types" {
  description = "insert eks node types"
  default = "t3.medium"
}
variable "eks_cluster_service_ipv4_cidr" {
  default = "10.100.0.0/16"
}


variable "launch_template" {
  type = map(object({
    ec2_type=string
    ami=string
    lt_name=string
    userdata = any
  }))
}

locals {

}
