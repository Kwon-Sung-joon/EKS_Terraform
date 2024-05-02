variable "dev_name_tag" {
  default = "dev"
}
variable "vpc_cidr" {
  description = "VPC CIDR BLOCK : x.x.x.x/x"
  type = map(object({
    vpc_cidr=string
    tags = any
  }))
  default = {}
}
variable "nat_gw" {
  type = map(object({
    public_subnet=string
    tags=any
  }))
  default = {}
}
variable "subnets" {
  type=map(object({
    vpc_id=any
    subnet_cidr=any
    subnet_az=any
    is_public=bool
    tags=any
  }))
  default = {}
}
variable "route_tables" {
  type = map(object({
    vpc_id = string
    route = any
    tags = any
    subnets = any
  }))
  default = {}
}
variable "iam_roles"{
  type=map(object({
    name=any
    tags=any
    assume_role_policy = any
    mgd_policies = set(string)
  }))
  default = {}
  }
variable "security_group" {
  type = map(object({
    name = string
    description = string
    vpc_id = string
    ingress = any
    egress = any
    tags = any
  }))
  default = {}
}
variable "launch_template" {
  type = map(object({
    name = string
    image_id = string
    instance_type = string
    vpc_security_group_ids = any
    user_data = any
  }))
  default = {}
}
variable "eks_cluster" {
  type = map(object({
    name = string
    subnets = any
    tags = any
    service_ipv4_cidr = string
    cluster_role = string
    cluster_version = number
    sg_ids= any
  }))
  default = {}
}
variable "eks_node_group" {
  type = map(object({
    cluster_name = string
    node_group_name = string
    node_group_role_arn = string
    subnet_ids = any
    scaling_config = any
    launch_template = any
    tags = any
  }))
  default = {}
}
variable "ec2_instance" {
  type = map(object({
    ami = string
    instance_type = string
    iam_instance_profile = string
    vpc_security_group_ids = list(string)
    subnet_id = string
    user_data = any
    tags = any
  }))
  default = {}
}


#VPC CIDR
locals {
  DEV_VPC={
    dev_vpc_1 = {
      vpc_cidr = "192.168.0.0/16"
      tags= {
        Name  = "${var.dev_name_tag}-vpc",
        Owner = "ksj"
      }
    }
  }
}

#NAT GW
locals {
  DEV_NAT_GW ={
    dev_nat_gw_1 = {
      public_subnet = module.subnets["pub1"].subnet_id
      tags = {
        Name = "dev_nat_gw"
        Owner = "ksj"
      }
    }
  }
}

#SUBNETS
locals {
  DEV_SUBNETS= {
    pub1 = {
      vpc_id      = module.vpc["dev_vpc_1"].vpc_id
      subnet_cidr = "192.168.0.0/24"
      subnet_az   = data.aws_availability_zones.available.names[0]
      is_public   = true
      tags= {
        Name  = "${var.dev_name_tag}-public-1",
        Owner = "ksj"
      }
    }
    pub2 = {
      vpc_id      = module.vpc["dev_vpc_1"].vpc_id
      subnet_cidr = "192.168.1.0/24"
      subnet_az   = data.aws_availability_zones.available.names[2]
      is_public   = true
      tags= {
        Name  = "${var.dev_name_tag}-public-2",
        Owner = "ksj"
      }
    }
    pri1 = {
      vpc_id      = module.vpc["dev_vpc_1"].vpc_id
      subnet_cidr = "192.168.2.0/24"
      subnet_az   = data.aws_availability_zones.available.names[0]
      is_public   = false
      tags= {
        Name  = "${var.dev_name_tag}-private-1",
        Owner = "ksj"
      }
    }
    pri2 = {
      vpc_id      = module.vpc["dev_vpc_1"].vpc_id
      subnet_cidr = "192.168.3.0/24"
      subnet_az   = data.aws_availability_zones.available.names[2]
      is_public   = false
      tags= {
        Name  = "${var.dev_name_tag}-private-2",
        Owner = "ksj"
      }
    }
  }
}


#ROUTE TABLES
locals {
  DEV_ROUTE_TABLE = {
    dev_public_route_table = {
      vpc_id = module.vpc["dev_vpc_1"].vpc_id
      tags = {
        Name = "public-route-table"
        Owner = "ksj"
      }
      route =[
        {
          cidr_block = "0.0.0.0/0"
          gateway_id = module.vpc["dev_vpc_1"].igw_id
        }
      ]
      subnets = [module.subnets["pub1"].subnet_id,module.subnets["pub2"].subnet_id]
    }

    dev_private_route_table = {
      vpc_id = module.vpc["dev_vpc_1"].vpc_id
      tags = {
        Name = "private-route-table"
        Owner = "ksj"
      }
      route =[
        {
          cidr_block = "0.0.0.0/0"
          gateway_id = module.nat_gw["dev_nat_gw_1"].nat_gw
        }
      ]
      subnets = [module.subnets["pri1"].subnet_id,module.subnets["pri2"].subnet_id]
    }
  }
}

#IAM ROLES
locals {
  DEV_IAM_ROLE = {
    dev_cluster_role = {
      name               = "dev_cluster_role"
      tags = {
        Name = "dev_cluster_role"
        Owner = "ksj"
      }
      assume_role_policy = data.aws_iam_policy_document.eks_cluster_role.json
      mgd_policies       = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      ]
    }
    dev_node_group_role = {
      name               = "dev_node_group_role"
      tags = {
        Name = "dev_node_group_role"
        Owner = "ksj"
      }
      assume_role_policy = data.aws_iam_policy_document.eks_node_group_role.json
      mgd_policies       = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
      ]
    }
    dev_ec2_eks_admin_role = {
      name               = "dev_ec2_eks_admin_role"
      tags = {
        Name = "dev_ec2_eks_admin_role"
        Owner = "ksj"
      }
      assume_role_policy = data.aws_iam_policy_document.dev_ec2_eks_admin_role.json
      mgd_policies       = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }
}
#SECURIT GROUPS
locals {
  DEV_SECURITY_GROUPS = {
    dev_eks_node_sg = {
      name = "eks-node-sg"
      description = "eks-node-sg"
      vpc_id = module.vpc["dev_vpc_1"].vpc_id
      ingress = {
        inbound_80 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 80
          ip_protocol = "tcp"
          to_port     = 80
          description = "inbound_80"
        }
        inbound_443 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 443
          ip_protocol = "tcp"
          to_port     = 443
          description = "inbound_443"
        }
      }
      egress = {
        outbound_any = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 0
          ip_protocol = "tcp"
          to_port     = 65535
          description = "outbound_any"
        }
      }
      tags= {
        Name  = "eks-node-sg",
        Owner = "ksj"
      }
    }
    dev_ec2_ssh_sg = {
      name = "ec2_ssh_sg"
      description = "ec2_ssh_sg"
      vpc_id = module.vpc["dev_vpc_1"].vpc_id
      ingress = {
        inbound_80 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 80
          ip_protocol = "tcp"
          to_port     = 80
          description = "inbound_80"
        }
        inbound_22 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 22
          ip_protocol = "tcp"
          to_port     = 22
          description = "inbound_22"
        }
      }
      egress = {
        outbound_any = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 0
          ip_protocol = "tcp"
          to_port     = 65535
          description = "outbound_any"
        }
      }
      tags= {
        Name  = "ec2_ssh_sg",
        Owner = "ksj"
      }
    }
    dev_eks_cluster_sg = {
      name = "dev_eks_cluster_sg"
      description = "dev_eks_cluster_sg"
      vpc_id = module.vpc["dev_vpc_1"].vpc_id
      ingress = {
        inbound_80 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 80
          ip_protocol = "tcp"
          to_port     = 80
          description = "inbound_80"
        }
        inbound_443 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 443
          ip_protocol = "tcp"
          to_port     = 443
          description = "inbound_443"
        }
      }
      egress = {
        outbound_any = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 0
          ip_protocol = "tcp"
          to_port     = 65535
          description = "outbound_any"
        }
      }
      tags= {
        Name  = "dev_eks_cluster_sg",
        Owner = "ksj"
      }
    }
  }
}
#LAUNCH TEMPLATES
locals {
  DEV_LAUNCH_TEMPLATES = {
    dev_eks_node_groups_lt = {
      name = "dev-eks-ng-lt"
      image_id = "ami-06aaf7c21e7e74e2a"
      instance_type = "t3.medium"
      vpc_security_group_ids = [module.security_groups["dev_eks_node_sg"].id]
      user_data = base64encode(templatefile("${path.module}/user_data/eks_node.sh",
        {
        CLUSTER-NAME = module.eks_cluster["dev_cluster_1"].cluster_name,
        B64-CLUSTER-CA     = module.eks_cluster["dev_cluster_1"].kubeconfig-certificate-authority-data,
        APISERVER-ENDPOINT = module.eks_cluster["dev_cluster_1"].endpoint,
        DNS-CLUSTER-IP = cidrhost(local.DEV_EKS_CLUSTER.dev_cluster_1.service_ipv4_cidr, 10)
        }
      )
      )
    }
  }
}
#EKS CLUSTERS
locals {
  DEV_EKS_CLUSTER = {
    dev_cluster_1 = {
      name = "dev_cluster_1"
      subnets = [module.subnets["pub1"].subnet_id,
        module.subnets["pub2"].subnet_id,
        module.subnets["pri1"].subnet_id,
        module.subnets["pri2"].subnet_id
      ]
      tags = {
        Name = "ksj-dev-cluster-1"
        Owner = "ksj"
      }
      service_ipv4_cidr = "10.100.0.0/16"
      cluster_role = module.iam_role["dev_cluster_role"].iam_role
      cluster_version = 1.26
      sg_ids = [module.security_groups["dev_eks_cluster_sg"].id]
    }
  }
}
#EKS NODE GROUP
locals {
  DEV_EKS_NODE_GROUP = {
    dev_eks_node_group_1 = {
      cluster_name = module.eks_cluster["dev_cluster_1"].cluster_name
      node_group_name = "${var.dev_name_tag}-eks-node-group-1"
      node_role_arn = module.iam_role["dev_node_group_role"].iam_role
      subnet_ids = [module.subnets["pub1"].subnet_id,
        module.subnets["pub2"].subnet_id,
        module.subnets["pri1"].subnet_id,
        module.subnets["pri2"].subnet_id
      ]
      scaling_config = [
        {
          desired_size = 1
          min_size     = 0
          max_size     = 1

        }

      ]
      launch_template = [
        {
          version = "$Latest"
          id = module.launch_template["dev_eks_node_groups_lt"].id
        }

      ]
      tags= {
        Name  = "${var.dev_name_tag}-eks-node-group-1",
        Owner = "ksj"
      }

    }
  }
}

#EC2 INSTANCE
locals {
  DEV_EC2_INSTANCE = {
    dev_ec2_eks_admin = {
      ami = "ami-07d95467596b97099"
      instance_type = "t2.micro"
      iam_role = module.iam_role["dev_ec2_eks_admin_role"].iam_role_name
      instance_profile_name = "dev_ec2_eks_admin_role_instance_profile"
      vpc_security_group_ids = [module.security_groups["dev_ec2_ssh_sg"].id]
      subnet_id = module.subnets["pub2"].subnet_id
      user_data = base64encode(templatefile("${path.module}/user_data/ec2_eks_admin.sh",
        {
          CLUSTER-NAME = module.eks_cluster["dev_cluster_1"].cluster_name
        }
      )
      )
      tags = {
        Name = "${var.dev_name_tag}-eks-admin",
        Owner = "ksj"
      }
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


/*
variable "launch_template" {
  type = map(object({
    ec2_type=string
    ami=string
    lt_name=string
    userdata = any
  }))
  default = {}
}
*/
