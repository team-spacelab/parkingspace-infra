resource "aws_s3_bucket" "uploads" {
  bucket_prefix = "parkingspace-uploads-"
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = [aws_route53_record.cloudfront.name]
    expose_headers = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_website_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  
  error_document {
    key = "index.html"
  }

  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "uploads" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cfoai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  policy = data.aws_iam_policy_document.uploads.json
}
