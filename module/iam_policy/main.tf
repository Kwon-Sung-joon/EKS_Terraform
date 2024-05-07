resource "aws_iam_policy" "policy" {
  name        = var.iam_policy_config.name
  description = var.iam_policy_config.description
  policy = file(var.iam_policy_config.policy)
  tags = var.iam_policy_config.tags
}

output "policy_arn" {
  value = aws_iam_policy.policy.arn
}