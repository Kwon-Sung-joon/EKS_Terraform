resource "aws_iam_role" "iam_role" {
  name = var.iam_role_config.name
  assume_role_policy = var.iam_role_config.assume_role_policy
  tags = var.iam_role_config.tags
}

resource "aws_iam_role_policy_attachment" "aws_iam_policy_attach" {
  role       = aws_iam_role.iam_role.name
  for_each   = toset(var.iam_role_config.mgd_policies)
  policy_arn = each.value
}

output "iam_role" {
  value = aws_iam_role.iam_role.arn
}
output "iam_role_name" {
  value = aws_iam_role.iam_role.name
}