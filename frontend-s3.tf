resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "parkingspace-frontend-"
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  error_document {
    key = "index.html"
  }

  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "frontend" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cfoai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend.json
}
