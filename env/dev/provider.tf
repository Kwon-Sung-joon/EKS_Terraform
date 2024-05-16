terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.3"
    }
  }
  backend "s3" {
    bucket  = "ksj-terraform-state-bucket"
    key     = "codebuild/dev/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}

provider "helm" {
  kubernetes {
    config_path = "/home/ec2-user/.kube/config"
  }
}
