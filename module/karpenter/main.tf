resource "aws_sqs_queue" "sqs" {
  name = var.karpenter_config.sqs.name
  message_retention_seconds = var.karpenter_config.sqs.message_retention_seconds
  sqs_managed_sse_enabled = var.karpenter_config.sqs.sqs_managed_sse_enabled
}
resource "aws_sqs_queue_policy" "sqs_policy" {
  policy    = var.karpenter_config.sqs.policy
  queue_url = aws_sqs_queue.sqs.id
}
/*
resource "aws_cloudwatch_event_rule" "event_rule" {

}

resource "aws_iam_policy" "" {
  policy = ""
}

resource "aws_iam_role" "" {
  assume_role_policy = ""
}
*/