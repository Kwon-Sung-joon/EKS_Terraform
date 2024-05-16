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


data "aws_iam_policy_document" "dev_elb_sa_role" {
  statement {
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/${module.iam_oidc["iam_oidc"].oidc_provider}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${module.iam_oidc["iam_oidc"].oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.iam_oidc["iam_oidc"].oidc_provider}:sub"
      values   = ["system:serviceaccount:${module.iam_oidc["iam_oidc"].oidc_provider}:${module.iam_oidc["iam_oidc"].oidc_provider}"]
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
