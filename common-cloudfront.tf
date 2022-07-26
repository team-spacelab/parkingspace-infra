resource "aws_cloudfront_origin_access_identity" "cfoai" { 
}

resource "aws_cloudfront_distribution" "cf" {
  origin {
    origin_id = "frontend"
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cfoai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id = "frontend"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    compress = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  enabled = true
  is_ipv6_enabled = true
  
  default_root_object = "index.html"

  aliases = ["parking.spacelab.work"]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.acmcert.arn
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
