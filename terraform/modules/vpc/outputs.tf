output "vpc_id" {
  description = "Identifiant du VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Plage d'adresses du VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_id" {
  description = "Identifiant du sous-réseau privé"
  value       = aws_subnet.private.id
}
