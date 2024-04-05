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
