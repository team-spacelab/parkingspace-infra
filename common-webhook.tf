resource "aws_sns_topic" "webhook" {
  name = "parkingspace-sns-cicd"
}

data "aws_iam_policy_document" "webhook_webhook" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.webhook.arn]
  }
}

resource "aws_sns_topic_policy" "webhook" {
  arn = aws_sns_topic.webhook.arn
  policy = data.aws_iam_policy_document.webhook_webhook.json
}

data "archive_file" "webhook_notification" {
  type = "zip"
  source_dir = "${path.module}/lambda/"
  output_path = "${path.module}/output/lambda.zip"
}

resource "aws_lambda_function" "webhook_notification" {
  filename = data.archive_file.webhook_notification.output_path
  function_name = "parkingspace-lambda-cicd-notification"
  handler = "notification.handler"
  source_code_hash = data.archive_file.webhook_notification.output_base64sha256
  role = aws_iam_role.webhook_notification.arn
  runtime = "nodejs16.x"

  environment {
    variables = {
      WEBHOOK_ID = ""
      WEBHOOK_TOKEN = ""
    }
  }

  lifecycle {
    ignore_changes = [
      environment
    ]
  }
}

resource "aws_iam_role" "webhook_notification" {
  name = "parkingspace-role-cicd-notification"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_sns_topic_subscription" "webhook_notification" {
  topic_arn = aws_sns_topic.webhook.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.webhook_notification.arn
}

resource "aws_lambda_permission" "webhook_notification" {
  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_notification.arn
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.webhook.arn
}
