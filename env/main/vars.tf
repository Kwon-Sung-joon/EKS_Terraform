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
variable "dev_eks_cluster_addons" {

  type = map(object({
    cluster_name =string
    addon_name = string
    /*
      check addon version
      aws eks describe-addon-versions --kubernetes-version 1.29 --addon-name vpc-cni \ --query 'addons[].addonVersions[].{Version: addonVersion, Defaultversion: compatibilities[0].defaultVersion}' --output table
    */
    addon_version = string
    /*
      NONE = Amazon EKS는 값을 변경하지 않습니다. 업데이트가 실패할 수 있습니다
      OVERWRITE =  Amazon EKS는 변경된 값을 다시 Amazon EKS 기본값으로 덮어씁니다
      PRESERVE = Amazon EKS가 값을 보존합니다. 이 옵션을 선택하는 경우 프로덕션 클러스터에서 추가 기능을 업데이트하기 전에 비프로덕션 클러스터에서 필드 및 값 변경 사항을 테스트하는 것이 좋습니다
    */
    resolve_conflicts_on_create = string
    resolve_conflicts_on_update = string
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
    create_namespace = bool
  }))
  default = {}
}
variable "k8s_manifest" {
  type = map(object({
    manifest = any
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
      policy = templatefile("${path.root}/template/KarpenterControllerPolicy.json", { ClusterName = "dev_cluster_1" , KarpenterNodeGroupRoleName = "dev_node_group_role"})
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
        inbound_6379 = {
          cidr_ipv4   = "0.0.0.0/0"
          from_port   = 6379
          ip_protocol = "tcp"
          to_port     = 6379
          description = "inbound_6379"
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
      image_id = "ami-0c970162f407cdfd0"
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
      subnets = [
        module.subnets["pri1"].subnet_id,
        module.subnets["pri2"].subnet_id
      ]
      tags = {
        Name = "ksj-dev-cluster-1"
        Owner = "ksj"
      }
      service_ipv4_cidr = "10.100.0.0/16"
      cluster_role = module.iam_role["dev_cluster_role"].iam_role
      cluster_version = 1.29
      sg_ids = [module.security_groups["dev_eks_cluster_sg"].id]
      node_group_role = module.iam_role["dev_node_group_role"].iam_role
      admin_role = module.iam_role["dev_ec2_eks_admin_role"].iam_role
      upload_kubeconfig = "s3://ksj-terraform-state-bucket/codebuild/dev/kubeconfig"
      endpoint_private_access = true
      endpoint_public_access = false
    }
  }
}
#EKS NODE GROUP
locals {
  DEV_EKS_NODE_GROUP = {
    dev_node_group_private = {
      cluster_name = module.eks_cluster["dev_cluster_1"].cluster_name
      node_group_name = "dev_node_group_private"
      node_role_arn = module.iam_role["dev_node_group_role"].iam_role
      subnet_ids = [
        module.subnets["pri1"].subnet_id,
        module.subnets["pri2"].subnet_id
      ]
      scaling_config = [
        {
          desired_size = 0
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
        Name  = "dev_node_group_private",
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
#IAM_ROLE_IRSA
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
    irsa_efs_csi_driver = {
      name = "irsa_efs_csi_driver"
      tags = {
        Name  = "irsa_efs_csi_driver"
        Owner = "ksj"
      }
      assume_role_policy = templatefile("${path.root}/template/AWS_EFS_CSI_Driver_Trust_Policy.json",{
        OIDC = "${module.eks_cluster["dev_cluster_1"].cluster_oidc_without_url}"
        NAMESPACE = "kube-system"
        SERVICE_ACCOUNT = "efs-csi-*"
      })
      mgd_policies = [
        "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
      ]
    }
    irsa_ebs_csi_driver = {
      name = "irsa_ebs_csi_driver"
      tags = {
        Name  = "irsa_ebs_csi_driver"
        Owner = "ksj"
      }
      assume_role_policy = templatefile("${path.root}/template/AWS_EBS_CSI_Driver_Trust_Policy.json",{
        OIDC = "${module.eks_cluster["dev_cluster_1"].cluster_oidc_without_url}"
        NAMESPACE = "kube-system"
        SERVICE_ACCOUNT = "ebs-csi-controller-sa"
      })
      mgd_policies = [
        "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      ]
    }
    irsa_aws_prometheus = {
      name = "amp-iamproxy-ingest-role"
      tags = {
        Name  = "irsa_aws_prometheus"
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
    irsa_keda = {
      name = "irsa_keda"
      tags = {
        Name  = "irsa_keda"
        Owner = "ksj"
      }
      assume_role_policy = templatefile("KEDA_IRSA_Trust_Policy.json",{
        OIDC = "${module.eks_cluster["dev_cluster_1"].cluster_oidc_without_url}"
        NAMESPACE = "keda"
        SERVICE_ACCOUNT = "keda-operator"
      })
      mgd_policies = [
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
      ]
    }
  }
}
#EKS CLUSTER ADDONS
locals {
  DEV_EKS_CLUSTER_ADDONS = {
    dev_core_dns = {
      cluster_name = "dev_cluster_1"
      addon_name = "coredns"
      /*
      check addon version
      aws eks describe-addon-versions --kubernetes-version 1.26 --addon-name vpc-cni \ --query 'addons[].addonVersions[].{Version: addonVersion, Defaultversion: compatibilities[0].defaultVersion}' --output table
      */
      addon_version = "v1.9.3-eksbuild.15"
      /*
      NONE = Amazon EKS는 값을 변경하지 않습니다. 업데이트가 실패할 수 있습니다
      OVERWRITE =  Amazon EKS는 변경된 값을 다시 Amazon EKS 기본값으로 덮어씁니다
      PRESERVE = Amazon EKS가 값을 보존합니다. 이 옵션을 선택하는 경우 프로덕션 클러스터에서 추가 기능을 업데이트하기 전에 비프로덕션 클러스터에서 필드 및 값 변경 사항을 테스트하는 것이 좋습니다
      */
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "PRESERVE"
    }
  }
}
#HELM RELEASE
locals {
  DEV_HELM = {
    dev_karpenter_chart = {
      repository = "oci://public.ecr.aws/karpenter"
      chart = "karpenter"
      namespace = "kube-system"
      name  = "karpenter"
      set   = [
        {
          name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
          value = "arn:aws:iam::<ACCOUNT_ID>:role/irsa_karpenter_controller"
        },
        {
          name  = "settings.clusterName"
          value = "dev_cluster_1"
        },
        {
          name  = "settings.interruptionQueue"
          value = "dev_karpenter_1_sqs"
        },
        {
          name  = "settings.featureGates.drift"
          value = "false"
        },
        {
          name  = "controller.resources.requests.cpu"
          value = "0.5"
        },
        {
          name  = "controller.resources.requests.memory"
          value = "512Mi"
        },
        {
          name  = "controller.resources.limits.cpu"
          value = "0.5"
        },
        {
          name  = "controller.resources.limits.memory"
          value = "512Mi"
        },
        {
          name  = "settings.featureGates.spotToSpotConsolidation"
          value = "true"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
          value = "100"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key"
          value = "karpenter.sh/nodepool"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator"
          value = "In"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]"
          value = "dev-private-node"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].weight"
          value = "1"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].key"
          value = "eks.amazonaws.com/nodegroup"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].operator"
          value = "In"
        },
        {
          name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].values[0]"
          value = "dev_node_group_private"
        },
        {
          name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution"
          value = "null"
        }
      ]
      create_namespace = true
    }
    dev_load_balancer_controller_chart = {
      repository = "https://aws.github.io/eks-charts"
      chart = "aws-load-balancer-controller"
      namespace = "kube-system"
      name  = "aws-load-balancer-controller"
      set   = [
        {
          name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
          value = "arn:aws:iam::<ACCOUNT_ID>:role/irsa_aws_load_balancer_controller"
        },
        {
          name  = "clusterName"
          value = "dev_cluster_1"
        },
        {
          name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
          value = "karpenter.sh/nodepool"
        },
        {
          name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
          value = "In"
        },
        {
          name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
          value = "dev-private-node"
        },
        {
          name  = "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].matchExpressions[0].key"
          value = "app.kubernetes.io/name"
        },
        {
          name  = "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].matchExpressions[0].operator"
          value = "In"
        },
        {
          name  = "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].matchExpressions[0].values[0]"
          value = "aws-load-balancer-controller"
        },
        {
          name  = "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey"
          value = "kubernetes.io/hostname"
        }
      ]
      create_namespace = true
    }
    }
}
#K8S MANIFEST
locals {
  DEV_K8S_MANIFEST = {
    dev_k8s_metrics = {
      manifest = file("${path.root}/manifest/metrics-server.yaml")
    }
    dev_karpenter_private_nodepool = {
      manifest = file("${path.root}/manifest/PrivateNodePool.yml")
    }
  }
}