# Fédération OIDC GitHub -> AWS : aucun identifiant statique n'est stocké dans GitHub.
# À chaque job, GitHub signe un jeton décrivant le contexte (dépôt, environnement).
# AWS vérifie la signature et les conditions ci-dessous, puis délivre des identifiants d'une heure.

locals {
  account_id  = split(":", aws_iam_openid_connect_provider.github.arn)[4]
  state_key   = "envs/dev/*"
  data_bucket = "arn:aws:s3:::${var.project}-data-*"
  app_role    = "arn:aws:iam::${local.account_id}:role/${var.project}-app-*"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = { Name = "github-actions" }
}

# Une politique de confiance par environnement GitHub. Le champ "sub" est comparé
# en égalité stricte : ni joker, ni autre dépôt, ni autre branche, ni PR.
data "aws_iam_policy_document" "trust" {
  for_each = toset(["dev-plan", "dev"])

  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:environment:${each.key}"]
    }
  }
}

# ---------------------------------------------------------------------------
# Rôle de PLAN : lecture seule. Endossable depuis l'environnement GitHub "dev-plan".
# ---------------------------------------------------------------------------
resource "aws_iam_role" "plan" {
  name                 = "${var.project}-gha-plan"
  description          = "GitHub Actions : terraform plan en lecture seule"
  assume_role_policy   = data.aws_iam_policy_document.trust["dev-plan"].json
  max_session_duration = 3600

  tags = { Name = "${var.project}-gha-plan" }
}

data "aws_iam_policy_document" "plan" {
  #checkov:skip=CKV_AWS_356:Les actions EC2 de description exigent Resource * ; lecture seule - expire le 2027-05-31

  statement {
    sid       = "LireEtat"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/${local.state_key}"]
  }

  statement {
    sid       = "ListerEtat"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "LireReseau"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }

  statement {
    sid       = "LireBucketsDuLab"
    effect    = "Allow"
    actions   = ["s3:Get*", "s3:List*"]
    resources = [local.data_bucket]
  }

  statement {
    sid       = "LireRolesDuLab"
    effect    = "Allow"
    actions   = ["iam:Get*", "iam:List*"]
    resources = [local.app_role]
  }
}

resource "aws_iam_role_policy" "plan" {
  name   = "plan-lecture-seule"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan.json
}

# ---------------------------------------------------------------------------
# Rôle de DÉPLOIEMENT : endossable uniquement depuis l'environnement GitHub "dev",
# qui exige une approbation manuelle.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "deploy" {
  name                 = "${var.project}-gha-deploy"
  description          = "GitHub Actions : terraform apply et destroy de l'environnement dev"
  assume_role_policy   = data.aws_iam_policy_document.trust["dev"].json
  max_session_duration = 3600

  tags = { Name = "${var.project}-gha-deploy" }
}

data "aws_iam_policy_document" "deploy" {
  #checkov:skip=CKV_AWS_111:Les actions EC2 de création n'acceptent pas de restriction par ressource ; bornées par région - expire le 2027-05-31
  #checkov:skip=CKV_AWS_356:Les actions EC2 de description exigent Resource * ; bornées par région - expire le 2027-05-31

  statement {
    sid       = "EtatLectureEcriture"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/${local.state_key}"]
  }

  statement {
    sid       = "ListerEtat"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  # Réseau : uniquement VPC, sous-réseau et security group, dans une seule région.
  # Ni instance, ni NAT Gateway, ni adresse IP publique : ces actions ne sont pas accordées.
  statement {
    sid    = "ReseauDuLab"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:ModifySecurityGroupRules",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  statement {
    sid    = "BucketsDuLab"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketTagging",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = [local.data_bucket, "${local.data_bucket}/*"]
  }

  statement {
    sid    = "RolesDuLabLectureEtSuppression"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = [local.app_role]
  }

  # Garde-fou contre l'élévation de privilèges : ce rôle ne peut créer ou modifier
  # un rôle applicatif QUE s'il porte la limite de permissions du lab.
  statement {
    sid       = "RolesDuLabSousLimite"
    effect    = "Allow"
    actions   = ["iam:CreateRole", "iam:PutRolePolicy"]
    resources = [local.app_role]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.app_boundary.arn]
    }
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploiement-du-lab"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

# Limite de permissions imposée aux rôles applicatifs : quoi que contienne leur
# politique, ils ne pourront jamais faire plus que lire les buckets de données du lab.
data "aws_iam_policy_document" "app_boundary" {
  statement {
    sid       = "LectureBucketsDuLab"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [local.data_bucket, "${local.data_bucket}/*"]
  }
}

resource "aws_iam_policy" "app_boundary" {
  name        = "${var.project}-app-boundary"
  description = "Limite de permissions des rôles applicatifs du lab"
  policy      = data.aws_iam_policy_document.app_boundary.json

  tags = { Name = "${var.project}-app-boundary" }
}
