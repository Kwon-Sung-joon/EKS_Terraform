resource "aws_iam_role" "iam_role" {
  name = var.iam_role_config.name
  assume_role_policy = var.iam_role_config.assume_role_policy
  tags = {
    Name  = var.iam_role_config.tag_name,
    Owner = "ksj"
  }
}

resource "aws_iam_role_policy_attachment" "aws_iam_policy_attach" {
  role       = aws_iam_role.iam_role.name
  for_each   = var.iam_role_config.mgd_policies
  policy_arn = each.value
}

output "test" {
  value=var.iam_role_config.mdg_policies
}
output "iam_role" {
  value = aws_iam_role.iam_role.arn
}