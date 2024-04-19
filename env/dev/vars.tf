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
    dev_vpc_1 = {
      vpc_cidr = "192.168.0.0/16"
      tags= {
        Name  = "${var.dev_name_tag}-vpc",
        Owner = "ksj"
      }
    }
  }
}

variable "nat_gw" {
  type = map(object({
    public_subnet=string
    tags=any
  }))
  default = {}
}
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

variable "route_tables" {
  type = map(object({
    vpc_id = string
    route = any
    tags = any
    subnets = any
  }))
  default = {}
}
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
      subnets = [module.subnets["pub1"].subnet_id,
        module.subnets["pub2"].subnet_id]
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
          gateway_id = module.nat_gw["nat_gw_1"].nat_gw
        }
      ]
      subnets = [module.subnets["pri1"].subnet_id,
        module.subnets["pri2"].subnet_id]
    }
  }
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
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
      ]
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
    tags = any
  }))
  default = {}
}
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
  }
}
