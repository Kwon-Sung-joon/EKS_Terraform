data "aws_availability_zones" "available" {
  state = "available"
}

variable "alltag" {
  description = "name"
}

variable "vpc_cidr" {
  description = "VPC CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.0.0/16"
}

variable "public_subnet1_cidr" {
  description = "Public Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.0.0/24"
}

variable "public_subnet2_cidr" {
  description = "Public Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.1.0/24"
}


variable "public_subnet1_az" {
  description = "Public Subnet AZ : 0(A)~3(D)"
  default     = 0
}


variable "public_subnet2_az" {
  description = "Public Subnet AZ : 0(A)~3(D)"
  default     = 2
}


variable "private_subnet1_cidr" {
  description = "Public Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.2.0/24"
}
variable "private_subnet2_cidr" {
  description = "Private Subnet CIDR BLOCK : x.x.x.x/x"
  default     = "192.168.3.0/24"
}

variable "private_subnet1_az" {
  description = "Private Subnet AZ : 0(A)~3(D)"
  default     = 0
}

variable "private_subnet2_az" {
  description = "Private Subnet AZ : 0(A)~3(D)"
  default     = 2
}


variable "ecr-repose-name" {
  description = "ECR Repository Name"

}
variable "bastionAmi" {
  description = "Bastion AMI"
  default     = "ami-0cbec04a61be382d9"
}
variable "bastionKey" {
  description = "Bastion Key Paire what you have."
  default     = "TerraformTest"
}


