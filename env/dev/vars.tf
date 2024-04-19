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
locals {
  DEV_VPC={
    dev_vpc = {
      vpc_cidr = "192.168.0.0/16"
      tags= {
        Name  = "${var.dev_name_tag}-vpc",
        Owner = "ksj"
      }
    }
  }
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
locals {
  DEV_PUBLIC_SUBNETS= {
    pub1 = {
      vpc_id      = module.vpc["dev_vpc"].vpc_id
      subnet_cidr = "192.168.0.0/24"
      subnet_az   = data.aws_availability_zones.available.names[0]
      is_public   = true
      tags= {
        Name  = "${var.dev_name_tag}-public-1",
        Owner = "ksj"
      }
    }
    pub2 = {
      vpc_id      = module.vpc["dev_vpc"].vpc_id
      subnet_cidr = "192.168.1.0/24"
      subnet_az   = data.aws_availability_zones.available.names[2]
      is_public   = true
      tags= {
        Name  = "${var.dev_name_tag}-public-2",
        Owner = "ksj"
      }
    }
  }
  DEV_PRIVATE_SUBNETS= {
    pri1 = {
      vpc_id      = module.vpc["dev_vpc"].vpc_id
      subnet_cidr = "192.168.2.0/24"
      subnet_az   = data.aws_availability_zones.available.names[0]
      is_public   = false
      tags= {
        Name  = "${var.dev_name_tag}-private-1",
        Owner = "ksj"
      }
    }
    pri2 = {
      vpc_id      = module.vpc["dev_vpc"].vpc_id
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

variable "route_tables" {
  type = map(object({
    vpc_id = string
    route = any
    tags = any
  }))
  default = {}
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

variable "security_group_rules" {
  type = map(object({
    name = string
    description = string
    vpc_id = string
    ingress = any
    egress = any
    alltag = any
  }))
  default = {}
}
locals {
  EC2_SECURITY_GROUPS = {
    eks_node_sg = {
      name = "eks-node-sg"
      description = "eks-node-sg"
      vpc_id = module.vpc["dev_vpc"].vpc_id
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
          description = "inbound_80"
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
      alltag = "eks-node-sg"
    }
    ec2_ssh_sg = {
      name = "ec2_ssh_sg"
      description = "ec2_ssh_sg"
      vpc_id = module.vpc["dev_vpc"].vpc_id
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
      alltag = "ec2-ssh-sg"
    }
  }
}


variable "nat_gw" {
  type = map(object({
    public_subnet=string
    alltag=string
  }))
  default = {}
}
locals {
  NAT_GW ={
    nat_gw_a = {
      public_subnet = module.public_subnets["pub1"].subnet_id
      alltag = "nat-A"
    }
  }
}



