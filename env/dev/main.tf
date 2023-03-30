provider "aws" {
  region = "ap-northeast-2"
}

terraform {
}

/*
terraform {
  backend "s3" {
    bucket  = "<put-your-bucket-name>"
    key     = "eksTf/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true

    dynamodb_table = "<put-your-dynamodb-table>"
  }
}
*/

module "vpc" {
  source = "../../module/vpc"

  vpc_cidr = var.vpc_cidr
  alltag   = var.alltag
}

module "public_subnet1" {
  source = "../../module/subnet"

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


module "public_subnet_rtb_igw" {
  source     = "../../module/rtb_igw"
  vpc_id     = module.vpc.vpc_id
  igw_id     = module.vpc.igw_id
  subnet_ids = [module.public_subnet1.subnet_id, module.public_subnet2.subnet_id]
  alltag     = var.alltag
}

module "eks_cluster" {
  source = "../../module/eks_cluster"
  subnet_id1 = module.public_subnet1.subnet_id
  subnet_id2 = module.public_subnet2.subnet_id
  alltag     = var.alltag
  depends_on = [
    aws_iam_role_policy_attachment.eks-role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-role-AmazonEKSVPCResourceController,
  ]
  eks-cluster-role = aws_iam_role.eks-cluster-role.arn
}


module "eks_node_groups" {
  source       = "../../module/eks_node_groups"
  alltag       = var.alltag
  cluster_name = module.eks_cluster.cluster_name
  subnet_id1   = module.public_subnet1.subnet_id
  subnet_id2   = module.public_subnet2.subnet_id
  node_types   = var.node_types
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.CloudWatchAgentServerPolicy,
    aws_iam_role_policy_attachment.CloudWatchLogsFullAccess,
  ]
  eks-ng-role = aws_iam_role.eks-node-group-iam-role.arn
}

/*
module "ecr_repos" {
  source         = "../../module/ecr"
  ecr-repos-name = var.ecr-repose-name
}
*/
module "bastion" {
  source       = "../../module/bastion"
  alltag       = var.alltag
  subnet_id1   = module.public_subnet1.subnet_id
  ami_id       = var.bastionAmi
  keypair_name = var.bastionKey
  vpc_id       = module.vpc.vpc_id
  user_data    = "./user_data/install_docker.sh"
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "${var.alltag}-eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    Name  = "${var.alltag}-IAM-ROLE-EKS-CLUSTER",
    Owner = "ksj"
  }
}

resource "aws_iam_role_policy_attachment" "eks-role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-role-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}


resource "aws_iam_role" "eks-node-group-iam-role" {
  name = "${var.alltag}-eks-node-group-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = {
    Name = "${var.alltag}-eks-node-group-iam-role"
  }

}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-group-iam-role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-group-iam-role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-group-iam-role.name
}


resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks-node-group-iam-role.name
}


resource "aws_iam_role_policy_attachment" "CloudWatchLogsFullAccess" {

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.eks-node-group-iam-role.name
}
