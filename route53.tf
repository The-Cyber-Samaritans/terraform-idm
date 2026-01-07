# Route53 DNS Records for ALB Ingress

# Get ALB details from ingress
data "aws_lb" "ingress" {
  count = var.create_ingress && var.create_dns_records ? 1 : 0

  name = regex("^([^-]+(?:-[^-]+){2,3})", kubernetes_ingress_v1.keycloak[0].status[0].load_balancer[0].ingress[0].hostname)[0]

  depends_on = [kubernetes_ingress_v1.keycloak]
}

# Primary domain A record (alias to ALB)
resource "aws_route53_record" "keycloak_a" {
  count = var.create_ingress && var.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.target[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.keycloak[0].status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = true
  }

  depends_on = [kubernetes_ingress_v1.keycloak]
}

# Primary domain AAAA record (IPv6 alias to ALB)
resource "aws_route53_record" "keycloak_aaaa" {
  count = var.create_ingress && var.create_dns_records ? 1 : 0

  zone_id = data.aws_route53_zone.target[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = kubernetes_ingress_v1.keycloak[0].status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = true
  }

  depends_on = [kubernetes_ingress_v1.keycloak]
}
