data "aws_availability_zones" "available" {
  state = "available"
}
variable "alltag" {
  description = "name"
  default = "test"
}
/*
variable "node_types" {
  description = "insert eks node types"
}
*/

variable "vpc_cidr" {
  description = "VPC CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.0.0/16"
}
variable "public_subnet1_cidr" {
  description = "Public Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.0.0/24"
}
variable "public_subnet2_cidr" {
  description = "Public Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.1.0/24"
}
variable "public_subnet1_az" {
  description = "Public Subnet AZ : 0(A)~3(D)"
  default     = 0
}
variable "public_subnet2_az" {
  description = "Public Subnet AZ : 0(A)~3(D)"
  default     = 2
}
variable "private_subnet1_cidr" {
  description = "Public Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.2.0/24"
}
variable "private_subnet2_cidr" {
  description = "Private Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.3.0/24"
}
variable "private_subnet1_az" {
  description = "Private Subnet AZ : 0(A)~3(D)"
  default     = 0
}
variable "private_subnet2_az" {
  description = "Private Subnet AZ : 0(A)~3(D)"
  default     = 2
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
  subnets={
    pub1={
      vpc_id=module.vpc.vpc_id
      subnet_cidr="192.168.0.0/24"
      subnet_az=data.aws_availability_zones.available.names[0]
      is_public=true
      alltag=var.alltag
    }
  pub2={
    vpc_id=module.vpc.vpc_id
    subnet_cidr="192.168.1.0/24"
    subnet_az=data.aws_availability_zones.available.names[2]
    is_public=true
    alltag=var.alltag
  }
  pri1={
    vpc_id=module.vpc.vpc_id
    subnet_cidr="192.168.2.0/24"
    subnet_az=data.aws_availability_zones.available.names[1]
    is_public=false
    alltag=var.alltag
  }
  pri2={
    vpc_id=module.vpc.vpc_id
    subnet_cidr="192.168.3.0/24"
    subnet_az=data.aws_availability_zones.available.names[3]
    is_public=false
    alltag=var.alltag
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
variable "mgd_policies_for_eks_cluster" {
  type = set(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ]
}

variable "mgd_policies_for_eks_node_group" {
  type = set(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]
}

variable "eks_cluster_service_ipv4_cidr" {
  default = "10.100.0.0/16"
}