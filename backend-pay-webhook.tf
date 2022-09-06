resource "aws_codestarnotifications_notification_rule" "payments" {
  detail_type    = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed"
  ]

  name     = "parkingspace-cicd-noti-payments"
  resource = aws_codepipeline.payments.arn

  target {
    address = aws_sns_topic.backend.arn
  }
}
