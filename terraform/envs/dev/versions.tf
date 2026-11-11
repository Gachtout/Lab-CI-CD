terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
  }

  # État distant dans S3, chiffré, avec verrou natif (fichier .tflock, sans DynamoDB).
  # Le nom du bucket n'est pas écrit ici : il est fourni à l'init par
  #   terraform init -backend-config=backend.hcl
  # Le fichier backend.hcl est produit par le bootstrap (voir étape 10).
  backend "s3" {
    key          = "envs/dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
