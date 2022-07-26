resource "aws_route53_zone" "r53zone" {
  name = "parking.spacelab.work."
}

resource "aws_route53_record" "cert" {
    for_each = {
    for dvo in aws_acm_certificate.acmcert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.r53zone.zone_id
}

resource "aws_route53_record" "cloudfront" {
  name = "parking.spacelab.work"
  type = "A"
  zone_id = aws_route53_zone.r53zone.zone_id

  alias {
    name = aws_cloudfront_distribution.cf.domain_name
    zone_id = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}
