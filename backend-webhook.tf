resource "aws_sns_topic" "backend" {
  name = "parkingspace-sns-cicd"
}

data "aws_iam_policy_document" "backend_webhook" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.backend.arn]
  }
}

resource "aws_sns_topic_policy" "backend" {
  arn = aws_sns_topic.backend.arn
  policy = data.aws_iam_policy_document.backend_webhook.json
}

data "archive_file" "backend_notification" {
  type = "zip"
  source_dir = "${path.module}/lambda/"
  output_path = "${path.module}/output/lambda.zip"
}

resource "aws_lambda_function" "backend_notification" {
  filename = data.archive_file.backend_notification.output_path
  function_name = "parkingspace-lambda-cicd-notification"
  handler = "notification.handler"
  source_code_hash = data.archive_file.backend_notification.output_base64sha256
  role = aws_iam_role.backend_notification.arn
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

resource "aws_iam_role" "backend_notification" {
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

resource "aws_sns_topic_subscription" "backend_notification" {
  topic_arn = aws_sns_topic.backend.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.backend_notification.arn
}

resource "aws_lambda_permission" "backend_notification" {
  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_notification.arn
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.backend.arn
}
