resource "aws_codestarnotifications_notification_rule" "bubblewrap" {
  detail_type    = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed"
  ]

  name     = "parkingspace-cicd-noti-bubblewrap"
  resource = aws_codepipeline.bubblewrap.arn

  target {
    address = aws_sns_topic.webhook.arn
  }
}
