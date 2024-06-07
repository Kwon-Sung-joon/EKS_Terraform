terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.3"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
  backend "s3" {
    bucket  = "ksj-terraform-state-bucket"
    key     = "codebuild/dev/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}
provider "kubernetes" {
  host                   = module.eks_cluster["dev_cluster_1"].endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster["dev_cluster_1"].kubeconfig-certificate-authority-data)
  config_path    = ""
  config_context = ""

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster["dev_cluster_1"].cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster["dev_cluster_1"].endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster["dev_cluster_1"].kubeconfig-certificate-authority-data)
    config_path    = ""
    config_context = ""
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster["dev_cluster_1"].cluster_name]
    }
  }
}
