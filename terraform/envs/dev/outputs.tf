output "vpc_id" {
  description = "Identifiant du VPC"
  value       = module.vpc.vpc_id
}

output "bucket_name" {
  description = "Nom du bucket de données"
  value       = module.data.bucket_name
}

output "app_role_arn" {
  description = "ARN du rôle applicatif"
  value       = module.app_role.role_arn
}

output "app_security_group_id" {
  description = "Identifiant du security group de l'application"
  value       = module.app_sg.security_group_id
}
