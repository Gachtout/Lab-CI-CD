provider "aws" {
  region = var.region

  # Mode hors ligne : permet `terraform plan` sans compte AWS (make plan, PR de forks).
  # Aucune de ces options n'est active lors d'un vrai déploiement.
  skip_credentials_validation = var.offline
  skip_requesting_account_id  = var.offline
  skip_metadata_api_check     = var.offline

  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}
