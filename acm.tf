data "aws_route53_zone" "primary" {
  name         = "${var.domain}"
  private_zone = false
}

resource "aws_acm_certificate" "mfa-acm" {
 domain_name               = "${var.domain}"
 subject_alternative_names = ["*.${var.domain}"]
 validation_method         = "DNS"
}

resource "aws_route53_record" "cert_validation" {
 name    = "${aws_acm_certificate.mfa-acm.domain_validation_options.0.resource_record_name}"
 type    = "${aws_acm_certificate.mfa-acm.domain_validation_options.0.resource_record_type}"
 zone_id = "${data.aws_route53_zone.primary.id}"
 records = ["${aws_acm_certificate.mfa-acm.domain_validation_options.0.resource_record_value}"]
 ttl     = 300
}