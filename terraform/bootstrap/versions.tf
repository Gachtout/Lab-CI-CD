terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
  }

  # État LOCAL, volontairement : ce module crée le bucket qui hébergera l'état des autres.
  # Il est appliqué une seule fois, à la main, par un administrateur du compte.
}

provider "aws" {
  region = var.region

  skip_credentials_validation = var.offline
  skip_requesting_account_id  = var.offline
  skip_metadata_api_check     = var.offline

  default_tags {
    tags = {
      Project     = var.project
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}
