data "aws_route53_zone" "route53_zone" {
  name = var.domain_name
}

resource "aws_acm_certificate" "app_domain_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_domain_record" {
  for_each = {
    for dvo in aws_acm_certificate.app_domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    if length(regexall("\\*\\..+", dvo.domain_name)) > 0
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.zone_id

}

resource "aws_acm_certificate_validation" "app_domain_validation" {
  certificate_arn         = aws_acm_certificate.app_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app_domain_record : record.fqdn]
}

