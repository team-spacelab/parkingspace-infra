resource "aws_codestarnotifications_notification_rule" "auth" {
  detail_type    = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed"
  ]

  name     = "parkingspace-cicd-noti-auth"
  resource = aws_codepipeline.auth.arn

  target {
    address = aws_sns_topic.backend.arn
  }
}
