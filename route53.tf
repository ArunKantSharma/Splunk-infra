data "aws_route53_zone" "splunk" {
  count = var.domain_name != "" ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "splunk_web" {
  count = var.domain_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.splunk[0].zone_id
  name    = var.splunk_web_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
    evaluate_target_health = true
  }
}
