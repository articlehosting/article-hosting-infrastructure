resource "aws_acm_certificate" "main_cert" {
  count                     = 1
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternative_names
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  zone_name                      = var.zone_name == "" ? var.domain_name : var.zone_name
  domain_validation_options_list = aws_acm_certificate.main_cert.0.domain_validation_options
}

data "aws_route53_zone" "default" {
  name         = "${local.zone_name}."
  private_zone = false
}

resource "aws_route53_record" "default" {
  count           = length(var.subject_alternative_names) + 1
  zone_id         = join("", data.aws_route53_zone.default.*.zone_id)
  ttl             = var.ttl
  allow_overwrite = true
  name            = lookup(local.domain_validation_options_list[count.index], "resource_record_name")
  type            = lookup(local.domain_validation_options_list[count.index], "resource_record_type")
  records         = [lookup(local.domain_validation_options_list[count.index], "resource_record_value")]
}

resource "aws_acm_certificate_validation" "default" {
  count                   = var.wait_for_certificate_issued ? 1 : 0
  certificate_arn         = join("", aws_acm_certificate.main_cert.*.arn)
  validation_record_fqdns = aws_route53_record.default.*.fqdn
}
