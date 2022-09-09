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

  origin {
    origin_id = "uploads"
    domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cfoai.cloudfront_access_identity_path
    }
  }

  origin {
    origin_id = "backend"
    domain_name = aws_lb.backend.dns_name

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    target_origin_id = "backend"
    allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE", "PATCH"]
    cached_methods = ["HEAD", "GET"]
    compress = false
    viewer_protocol_policy = "https-only"
    path_pattern = "/api/*"

    forwarded_values {
      query_string = true

      headers = ["*"]

      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    target_origin_id = "uploads"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["HEAD", "GET"]
    compress = true
    viewer_protocol_policy = "https-only"
    path_pattern = "/uploads/*"

    forwarded_values {
      query_string = false

      headers = []

      cookies {
        forward = "none"
      }
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

  custom_error_response {
    error_code = 403
    response_code = 200
    response_page_path = "/"
    error_caching_min_ttl = 0
  }
}
