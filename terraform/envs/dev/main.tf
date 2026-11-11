# Environnement dev : uniquement des ressources gratuites (VPC, security group, S3, IAM).
# Ni EC2, ni NAT Gateway, ni base de données : une policy l'interdit (policies/cout.rego).

module "vpc" {
  source = "../../modules/vpc"

  name              = var.project
  availability_zone = "${var.region}a"
}

module "app_sg" {
  source = "../../modules/security_group"

  name          = "${var.project}-app"
  vpc_id        = module.vpc.vpc_id
  ingress_cidrs = var.app_ingress_cidrs
  egress_cidr   = module.vpc.vpc_cidr
}

module "data" {
  source = "../../modules/s3"

  name                = "${var.project}-data"
  block_public_access = true
  force_destroy       = true # lab : le workflow destroy doit pouvoir tout supprimer
}

module "app_role" {
  source = "../../modules/iam"

  name       = "${var.project}-app"
  bucket_arn = module.data.bucket_arn
}
