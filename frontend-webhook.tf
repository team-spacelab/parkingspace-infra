resource "aws_codestarnotifications_notification_rule" "frontend" {
  detail_type    = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed"
  ]

  name     = "parkingspace-cicd-noti-frontend"
  resource = aws_codepipeline.frontend.arn

  target {
    address = aws_sns_topic.webhook.arn
  }
}
