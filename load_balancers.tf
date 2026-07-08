resource "aws_eip" "nlb" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb-eip"
  })

  depends_on = [aws_internet_gateway.splunk]
}

resource "aws_lb" "nlb" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb.id]

  subnet_mapping {
    subnet_id     = aws_subnet.public[0].id
    allocation_id = aws_eip.nlb.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb"
  })
}

resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb"
  })
}

resource "aws_lb_target_group" "splunk_web" {
  name     = "${var.project_name}-sh-web-tg"
  port     = local.splunk_ports.web_ui
  protocol = "HTTP"
  vpc_id   = aws_vpc.splunk.id

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sh-web-tg"
  })
}

resource "aws_lb_target_group_attachment" "search_heads" {
  for_each = { for k in local.search_head_cluster_keys : k => local.splunk_instances[k] }

  target_group_arn = aws_lb_target_group.splunk_web.arn
  target_id        = aws_instance.splunk[each.key].id
  port             = local.splunk_ports.web_ui
}

locals {
  alb_certificate_arn = var.domain_name != "" ? aws_acm_certificate_validation.splunk[0].certificate_arn : var.certificate_arn
  enable_https        = local.alb_certificate_arn != ""
}

resource "aws_lb_listener" "alb_https" {
  count = local.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.alb.arn
  port              = local.splunk_ports.https
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.splunk_web.arn
  }
}

resource "aws_lb_listener" "alb_web" {
  load_balancer_arn = aws_lb.alb.arn
  port              = local.splunk_ports.web_ui
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.splunk_web.arn
  }
}

resource "aws_lb_target_group" "nlb_to_alb_https" {
  count = local.enable_https ? 1 : 0

  name        = "${var.project_name}-nlb-alb-443"
  port        = local.splunk_ports.https
  protocol    = "TCP"
  vpc_id      = aws_vpc.splunk.id
  target_type = "alb"

  health_check {
    enabled  = true
    protocol = "HTTPS"
    port     = "443"
    path     = "/"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb-alb-443"
  })
}

resource "aws_lb_target_group" "nlb_to_alb_web" {
  name        = "${var.project_name}-nlb-alb-8000"
  port        = local.splunk_ports.web_ui
  protocol    = "TCP"
  vpc_id      = aws_vpc.splunk.id
  target_type = "alb"

  health_check {
    enabled  = true
    protocol = "HTTP"
    port     = "8000"
    path     = "/"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb-alb-8000"
  })
}

resource "aws_lb_target_group_attachment" "nlb_to_alb_https" {
  count = local.enable_https ? 1 : 0

  target_group_arn = aws_lb_target_group.nlb_to_alb_https[0].arn
  target_id        = aws_lb.alb.arn
  port             = aws_lb_listener.alb_https[0].port

  depends_on = [aws_lb_listener.alb_https]
}

resource "aws_lb_target_group_attachment" "nlb_to_alb_web" {
  target_group_arn = aws_lb_target_group.nlb_to_alb_web.arn
  target_id        = aws_lb.alb.arn
  port             = aws_lb_listener.alb_web.port

  depends_on = [aws_lb_listener.alb_web]
}

resource "aws_lb_listener" "nlb_https" {
  count = local.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.nlb.arn
  port              = local.splunk_ports.https
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_alb_https[0].arn
  }

  depends_on = [aws_lb_target_group_attachment.nlb_to_alb_https]
}

resource "aws_lb_listener" "nlb_web" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = local.splunk_ports.web_ui
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_to_alb_web.arn
  }

  depends_on = [aws_lb_target_group_attachment.nlb_to_alb_web]
}

resource "aws_acm_certificate" "splunk" {
  count = var.domain_name != "" ? 1 : 0

  domain_name       = "${var.splunk_web_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cert"
  })
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.splunk[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = data.aws_route53_zone.splunk[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "splunk" {
  count = var.domain_name != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.splunk[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
