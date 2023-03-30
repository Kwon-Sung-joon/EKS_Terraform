
resource "aws_ecr_repository" "ecr-repos" {
  name                 = "${var.ecr-repos-name}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
