output "state_bucket" {
  description = "Bucket de l'état Terraform (variable GitHub TF_STATE_BUCKET)"
  value       = aws_s3_bucket.state.id
}

output "plan_role_arn" {
  description = "Rôle de plan (variable GitHub AWS_PLAN_ROLE_ARN)"
  value       = aws_iam_role.plan.arn
}

output "deploy_role_arn" {
  description = "Rôle de déploiement (variable GitHub AWS_DEPLOY_ROLE_ARN)"
  value       = aws_iam_role.deploy.arn
}

output "app_boundary_arn" {
  description = "Limite de permissions des rôles applicatifs (variable GitHub APP_BOUNDARY_ARN)"
  value       = aws_iam_policy.app_boundary.arn
}

output "region" {
  description = "Région (variable GitHub AWS_REGION)"
  value       = var.region
}
