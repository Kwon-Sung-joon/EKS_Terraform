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
