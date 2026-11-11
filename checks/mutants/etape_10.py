"""Mutants de l'étape 10 : une contrainte retirée par mutant."""
from mut import DEPLOY, del_block, in_job, in_target, remove, resub

BOOT = "terraform/bootstrap"


def c1():
    """fournisseur d'identité pointant ailleurs que GitHub Actions"""
    resub(f"{BOOT}/oidc.tf", r'"https://token\.actions\.githubusercontent\.com"', '"https://example.org"')


def c2():
    """comparaison du sujet par motif"""
    resub(f"{BOOT}/oidc.tf", r'"StringEquals"(\n\s+variable = "token\.actions\.githubusercontent\.com:sub")', r'"StringLike"\1')


def c2b():
    """sujet avec joker"""
    resub(f"{BOOT}/oidc.tf", r":environment:\$\{each\.key\}", ":*")


def c3():
    """condition sur l'audience retirée"""
    resub(f"{BOOT}/oidc.tf", r"githubusercontent\.com:aud", "githubusercontent.com:azp")


def c4():
    """bucket d'état sans versioning"""
    del_block(f"{BOOT}/state.tf", r'resource "aws_s3_bucket_versioning"')


def c5():
    """alerte de budget supprimée"""
    remove(f"{BOOT}/budget.tf")


def c6():
    """clé d'accès statique dans le workflow de déploiement"""
    in_job(DEPLOY, "apply", r"(\n          role-to-assume:[^\n]*)", r"\1\n          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}")


def c7():
    """apply hors de tout environnement, donc sans approbation"""
    in_job(DEPLOY, "apply", r"\n    environment: dev", "")


def c8():
    """déploiement déclenchable par une pull request"""
    resub(DEPLOY, r"^on:\n", "on:\n  pull_request:\n")


def c9():
    """toutes les actions accordées au rôle de déploiement"""
    resub(f"{BOOT}/oidc.tf", r'actions   = \["s3:GetObject", "s3:PutObject", "s3:DeleteObject"\]', 'actions   = ["*"]')


def c10():
    """apply sans confirmation explicite"""
    in_target("aws-apply", r'\t@test "\$\$\{AWS_CONFIRM[^\n]*\n', "")
