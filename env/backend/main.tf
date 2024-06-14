terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  region = "ap-northeast-2"
}
resource "aws_dynamodb_table" "ksj-tf-state-lock" {
  name           = "ksj-tf-state-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
resource "aws_s3_bucket" "ksj-tf-logs" {
  bucket = "ksj-tf-bcknd"
  acl    = "log-delivery-write"

}
resource "aws_s3_bucket" "ksj-tf-state" {
  bucket = "ksj-tf-state"
  acl    = "private"
  versioning {
    enabled = true
  }
  logging {
    target_bucket = aws_s3_bucket.ksj-tf-logs.id
    target_prefix = "log/"
  }
  lifecycle {
    prevent_destroy = true
  }
}
