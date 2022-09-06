resource "aws_codestarnotifications_notification_rule" "space" {
  detail_type    = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-stage-execution-succeeded",
    "codepipeline-pipeline-stage-execution-failed"
  ]

  name     = "parkingspace-cicd-noti-space"
  resource = aws_codepipeline.space.arn

  target {
    address = aws_sns_topic.backend.arn
  }
}
