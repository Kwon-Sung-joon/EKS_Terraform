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
    config_raw = base64decode(data.aws_s3_bucket_object.kubeconfig.body)
}
