resource "aws_iam_role" "iam_role" {
  name = var.name
  assume_role_policy = var.assume_role_policy
  tags = {
    Name  = var.tag_name,
    Owner = "ksj"
  }
}

resource "aws_iam_role_policy_attachment" "aws_iam_policy_attach" {
  role       = aws_iam_role.iam_role.name
  for_each   = var.mgd_policies
  policy_arn = each.value
}
output "iam_role" {
  value = aws_iam_role.iam_role.arn
}