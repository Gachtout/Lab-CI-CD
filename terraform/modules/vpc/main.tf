# VPC minimal : un sous-réseau privé, aucune passerelle Internet, aucune NAT Gateway.
# Tout ce module est gratuit ; une NAT Gateway coûterait environ 30 € par mois.

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

# Le security group par défaut d'un VPC autorise tout le trafic interne.
# On le reprend sous gestion Terraform, sans aucune règle : il ne laisse plus rien passer.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-default-ferme" }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, 1)
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = { Name = "${var.name}-prive" }
}
