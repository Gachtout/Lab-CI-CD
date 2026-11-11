# Security group de l'application : HTTPS entrant depuis des plages explicites uniquement.

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Flux HTTPS de l'application ${var.name}"
  vpc_id      = var.vpc_id

  tags = { Name = var.name }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = toset(var.ingress_cidrs)

  security_group_id = aws_security_group.this.id
  description       = "HTTPS depuis ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS sortant vers le VPC uniquement"
  cidr_ipv4         = var.egress_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
