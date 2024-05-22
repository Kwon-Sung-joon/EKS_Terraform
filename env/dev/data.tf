data "aws_iam_policy_document" "eks_cluster_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["eks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "eks_node_group_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "dev_ec2_eks_admin_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "tls_certificate" "dev_eks_cluster_1_oidc" {
  url = module.eks_cluster["dev_cluster_1"].cluster_oidc
}

data "aws_s3_bucket_object" "kubeconfig" {
  bucket  = "ksj-terraform-state-bucket"
  key     = "codebuild/dev/kubeconfig"
}

data "aws_iam_policy_document" "karpenter_sqs_policy"{
  statement {
    actions = ["sqs:SendMessage"]
    principals {
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
      type        = "Service"
    }
  }
}
variable "dev_cluster_1_karpenter" {
  default = "dev_cluster_1"
}

data "aws_iam_policy_document" "dev_cluster_1_karpenter_controller_policy" {
    statement {
      sid = "Karpenter"

      actions = [
        "ssm:GetParameter",
        "ec2:DescribeImages",
        "ec2:RunInstances",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeAvailabilityZones",
        "ec2:DeleteLaunchTemplate",
        "ec2:CreateTags",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateFleet",
        "ec2:DescribeSpotPriceHistory",
        "pricing:GetProducts",
      ]

      effect = "Allow"
      resources = ["*"]
    }

    statement {
      sid = "ConditionalEC2Termination"

      actions = ["ec2:TerminateInstances"]

      effect = "Allow"
      resources = ["*"]

      condition {
        test     = "StringLike"
        variable = "ec2:ResourceTag/karpenter.sh/nodepool"
        values   = ["*"]
      }
    }

    statement {
      sid = "PassNodeIAMRole"

      actions = ["iam:PassRole"]

      effect = "Allow"
      resources = ["arn:aws:iam::*:role/KarpenterNodeRole-${var.dev_cluster_1_karpenter}"]
    }

    statement {
      sid = "EKSClusterEndpointLookup"

      actions = ["eks:DescribeCluster"]

      effect = "Allow"
      resources = ["arn:aws:eks:ap-northeast-2:*:cluster/${var.dev_cluster_1_karpenter}"]
    }

    statement {
      sid = "AllowScopedInstanceProfileCreationActions"

      actions = ["iam:CreateInstanceProfile"]

      effect = "Allow"
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "aws:RequestTag/kubernetes.io/cluster/${var.dev_cluster_1_karpenter}"
        values   = ["owned"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:RequestTag/topology.kubernetes.io/region"
        values   = ["ap-northeast-2"]
      }

      condition {
        test     = "StringLike"
        variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
        values   = ["*"]
      }
    }

    statement {
      sid = "AllowScopedInstanceProfileTagActions"

      actions = ["iam:TagInstanceProfile"]

      effect = "Allow"
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/kubernetes.io/cluster/${var.dev_cluster_1_karpenter}"
        values   = ["owned"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/topology.kubernetes.io/region"
        values   = ["ap-northeast-2"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:RequestTag/kubernetes.io/cluster/${var.dev_cluster_1_karpenter}"
        values   = ["owned"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:RequestTag/topology.kubernetes.io/region"
        values   = ["ap-northeast-2"]
      }

      condition {
        test     = "StringLike"
        variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
        values   = ["*"]
      }

      condition {
        test     = "StringLike"
        variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
        values   = ["*"]
      }
    }

    statement {
      sid = "AllowScopedInstanceProfileActions"

      actions = [
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:DeleteInstanceProfile",
      ]

      effect = "Allow"
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/kubernetes.io/cluster/${var.dev_cluster_1_karpenter}"
        values   = ["owned"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/topology.kubernetes.io/region"
        values   = ["ap-northeast-2"]
      }

      condition {
        test     = "StringLike"
        variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
        values   = ["*"]
      }
    }
    statement {
      sid = "AllowInstanceProfileReadActions"

      actions = ["iam:GetInstanceProfile"]

      effect = "Allow"
      resources = ["*"]
    }
}

/*
data "aws_iam_policy_document" "dev_elb_sa_role" {
  statement {
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/arn:aws:iam::<ACCOUNT>:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/42AA06C0891D619DB25EEF90FD53D2AC"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "arn:aws:iam::<ACCOUNT>:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/42AA06C0891D619DB25EEF90FD53D2AC:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "arn:aws:iam::<ACCOUNT>:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/42AA06C0891D619DB25EEF90FD53D2AC:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}


/*
data "template_file" "eks_userdata" {
  template = "./user_data/eks_node.sh"
  vars = {
    B64-CLUSTER-CA     = module.eks_cluster.kubeconfig-certificate-authority-data
    APISERVER-ENDPOINT = module.eks_cluster.endpoint
    DNS-CLUSTER-IP     = cidrhost(var.vpc_cidr, 10)
  }
}
*/
