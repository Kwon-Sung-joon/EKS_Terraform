variable "account_id" {
  default = "672956273056"
}
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

variable "iam_policies" {
  type = map(object({
    name = string
    policy = any
    description = string
    tags = any
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
    update_default_version = bool
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
    node_group_role = string
    admin_role = string
    endpoint_private_access = bool
    endpoint_public_access = bool
    upload_kubeconfig = string
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

variable "iam_oidc" {
  type = map(object({
    url = any
    client_id_list = any
    thumbprint_list = any
  }))
  default = {}
}

variable "helm_release" {
  type = map(object({
    chart = any
    name = string
    set = any
  }))
  default = {}
}
variable "k8s_service_account" {
  type = map(object({
    metadata = any
  }))
  default = {}
}

variable "k8s_karpenter" {
  type = map(object({
    sqs = any
    event_rules = any
    instance_profile = string
  }))
  default = {}
}
#KARPENTER
locals {
  DEV_KARPENTER = {
    dev_karpenter_1 = {
      sqs = {
        name = "dev_karpenter_1_sqs"
        message_retention_seconds = 300
        sqs_managed_sse_enabled = true
        policy = data.aws_iam_policy_document.karpenter_sqs_policy.json
      }
      event_rules = {
        ScheduledChangeRule = {
          name          = "ScheduledChangeRule"
          description   = "ScheduledChangeRule"
          event_pattern = jsonencode(
            {
              "source" : ["aws.health"],
              "detail-type" : ["AWS Health Event"]
            })
        }
        SpotInterruptionRule = {
          name          = "SpotInterruptionRule"
          description   = "SpotInterruptionRule"
          event_pattern = jsonencode(
            {
              "source" : ["aws.ec2"],
              "detail-type" : ["EC2 Spot Instance Interruption Warning"]
            })
        }
        RebalanceRule = {
          name          = "RebalanceRule"
          description   = "RebalanceRule"
          event_pattern = jsonencode(
            {
              "source" : ["aws.ec2"],
              "detail-type" : ["EC2 Instance Rebalance Recommendation"]
            })
        }
        RebalanceRule = {
          name          = "InstanceStateChangeRule"
          description   = "InstanceStateChangeRule"
          event_pattern = jsonencode(
            {
              "source" : ["aws.ec2"],
              "detail-type" : ["EC2 Instance State-change Notification"]
            })
        }
      }
      instance_profile = module.iam_role["dev_node_group_role"].iam_role_name
    }
  }
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
#        {
#          cidr_block = "0.0.0.0/0"
#          gateway_id = module.nat_gw["dev_nat_gw_1"].nat_gw
#        }
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
        "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
        module.iam_policy["dev_node_group_policy"].policy_arn
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

#IAM POLICY
locals {
  DEV_IAM_POLICY = {
    dev_node_group_policy = {
      name = "dev_node_group_policy"
      description = "ecr policy for node group"
      policy = templatefile("${path.root}/template/NodeECR_Policy.json",{} )
      tags = {
        Name = "dev_node_group_policy"
        Owner = "ksj"
      }
    }
    dev_irsa_elb_controller_policy = {
      name = "dev_irsa_elb_controller_policy"
      description = "irsa for elb controller"
      policy = templatefile("${path.root}/template/AWS_LB_Controller_Policy.json", {})
      tags = {
        Name = "dev_irsa_elb_controller_policy"
        Owner = "ksj"
      }
    }
    dev_irsa_karpenter_policy = {
      name = "dev_irsa_karpenter_policy"
      description = "irsa for karpenter controller"
      #policy = "${path.root}/template/KarpenterControllerPolicy.json"
      policy = templatefile("${path.root}/template/KarpenterControllerPolicy.json", { CLUSTER_NAME = "dev_cluster_1" })
      tags = {
        Name = "dev_irsa_karpenter_policy"
        Owner = "ksj"
      }
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
        inbound_9443 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 9443
          ip_protocol = "tcp"
          to_port     = 9443
          description = "inbound_9443"
        }
        inbound_8080 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 8080
          ip_protocol = "tcp"
          to_port     = 8080
          description = "inbound_8080"
        }
        inbound_10250 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 10250
          ip_protocol = "tcp"
          to_port     = 10250
          description = "inbound_10250"
        }
        inbound_10250 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 10250
          ip_protocol = "tcp"
          to_port     = 10250
          description = "inbound_10250"
        }
        inbound_8081 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 8081
          ip_protocol = "tcp"
          to_port     = 8081
          description = "inbound_8081"
        }
        inbound_8000 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 8000
          ip_protocol = "tcp"
          to_port     = 8000
          description = "inbound_8000"
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
      instance_type = "t3a.medium"
      update_default_version = false
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
      node_group_role = module.iam_role["dev_node_group_role"].iam_role
      admin_role = module.iam_role["dev_ec2_eks_admin_role"].iam_role
      upload_kubeconfig = "s3://ksj-terraform-state-bucket/codebuild/dev/kubeconfig"
      endpoint_private_access = true
      endpoint_public_access = true
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
        module.subnets["pub2"].subnet_id
      ]
/*
      subnet_ids = [module.subnets["pub1"].subnet_id,
        module.subnets["pub2"].subnet_id,
        module.subnets["pri1"].subnet_id,
        module.subnets["pri2"].subnet_id
      ]
*/
      scaling_config = [
        {
          desired_size = 2
          min_size     = 0
          max_size     = 3

        }

      ]
      launch_template = [
        {
          version = "$Default"
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
      instance_profile_name = module.iam_role["dev_ec2_eks_admin_role"].iam_role_name
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

#IAM OIDC
locals {
  DEV_IAM_OIDC = {
    iam_oidc = {
      url = module.eks_cluster["dev_cluster_1"].cluster_oidc
      client_id_list = ["sts.amazonaws.com"]
      thumbprint_list = [data.tls_certificate.dev_eks_cluster_1_oidc.certificates.0.sha1_fingerprint]
    }
  }
}

#DEV_IAM_ROLE_IRSA
locals {
  DEV_IAM_ROLE_IRSA = {
    irsa_aws_load_balancer_controller = {
      name = "irsa_aws_load_balancer_controller"
      tags = {
        Name  = "irsa_aws_load_balancer_controller"
        Owner = "ksj"
      }
      assume_role_policy = templatefile("${path.root}/template/EKS_IRSA_Trust_Policy.json",{
        OIDC = "${module.eks_cluster["dev_cluster_1"].cluster_oidc_without_url}"
        NAMESPACE = "kube-system"
        SERVICE_ACCOUNT = "aws-load-balancer-controller"
      })
      mgd_policies = [
       module.iam_policy["dev_irsa_elb_controller_policy"].policy_arn
      ]
    }
    irsa_karpenter_controller = {
      name = "irsa_karpenter_controller"
      tags = {
        Name  = "irsa_karpenter_controller"
        Owner = "ksj"
      }
      assume_role_policy = templatefile("${path.root}/template/EKS_IRSA_Trust_Policy.json",{
        OIDC = "${module.eks_cluster["dev_cluster_1"].cluster_oidc_without_url}"
        NAMESPACE = "kube-system"
        SERVICE_ACCOUNT = "karpenter"
      })
      mgd_policies = [
        module.iam_policy["dev_irsa_karpenter_policy"].policy_arn
      ]
    }
  }
}
/*
#K8S SERVICE ACCOUNT
locals {
  DEV_K8S_SERVICE_ACCOUNT = {
    dev_elb_sa = {
      metadata = [
        {
          name      = "aws-load-balancer-controller"
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name"      = "aws-load-balancer-controller"
            "app.kubernetes.io/component" = "controller"
          }
          annotations = {
            "eks.amazonaws.com/role-arn"               = module.iam_role["dev_elb_sa_role"].iam_role
            "eks.amazonaws.com/sts-regional-endpoints" = "true"
          }
        }
      ]

    }
  }
}

#HELM RELEASE
locals {
  DEV_HELM = {
    dev_elb_controller_chart = {
      repository = "https://aws.github.io/eks-charts"
      chart = "aws-load-balancer-controller"
      namespace = "kube-system"
      name  = "aws-load-balancer-controller"
      set   = [
        {
          name  = "region"
          value = "ap-northeast-2"
        },
        {
          name  = "serviceAccount.create"
          value = false
        },
        {
          name  = "serviceAccount.name"
          value = "aws-load-balancer-controller"
        },
        {
          name  = "clusterName"
          value = "dev_cluster_1"
        }
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
