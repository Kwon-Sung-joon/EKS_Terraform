resource "aws_sqs_queue" "sqs" {
  name = var.karpenter_config.sqs.name
  message_retention_seconds = var.karpenter_config.sqs.message_retention_seconds
  sqs_managed_sse_enabled = var.karpenter_config.sqs.sqs_managed_sse_enabled
}
resource "aws_sqs_queue_policy" "sqs_policy" {
  policy    = var.karpenter_config.sqs.policy
  queue_url = aws_sqs_queue.sqs.id
}


resource "aws_cloudwatch_event_rule" "event_rule" {
  for_each = var.karpenter_config.event_rules
  name = each.value.name
  description = each.value.description
  event_pattern = each.value.event_pattern

#  name = var.karpenter_config.event_rule.name
#  description = var.karpenter_config.event_rule.description
#  event_pattern = var.karpenter_config.event_rule.event_pattern
}
resource "aws_cloudwatch_event_target" "event_target" {
  for_each = var.karpenter_config.event_rules
  rule = each.value.name
  arn  = aws_sqs_queue.sqs.arn
}


/*
resource "aws_iam_policy" "" {
  policy = ""
}

resource "aws_iam_role" "" {
  assume_role_policy = ""
}
*/