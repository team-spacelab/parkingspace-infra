resource "aws_acm_certificate" "acmcert" {
  provider = aws.n_verginia
  domain_name = "parking.spacelab.work"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "acmcert" {
  provider = aws.n_verginia
  certificate_arn = aws_acm_certificate.acmcert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
}
