# Rôle applicatif en moindre privilège : lecture seule sur un bucket précis.

data "aws_iam_policy_document" "assume" {
  statement {
    sid     = "ServiceAutorise"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.trusted_service]
    }
  }
}

resource "aws_iam_role" "app" {
  name_prefix        = "${var.name}-"
  description        = "Rôle de l'application ${var.name} : lecture du bucket de données"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = { Name = var.name }
}

data "aws_iam_policy_document" "read_bucket" {
  statement {
    sid       = "ListerLeBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]
  }

  statement {
    sid       = "LireLesObjets"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "read_bucket" {
  name   = "lecture-bucket"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.read_bucket.json
}
