output "role_arn" {
  description = "ARN du rôle applicatif"
  value       = aws_iam_role.app.arn
}
