output "security_group_id" {
  description = "Identifiant du security group"
  value       = aws_security_group.this.id
}
