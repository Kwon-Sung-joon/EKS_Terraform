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