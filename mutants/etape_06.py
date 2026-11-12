"""Mutants de l'étape 6 : une contrainte retirée par mutant."""
from mut import PLAN, append, del_block, in_job, in_target, remove, resub

ENV = "terraform/envs/dev"


def c1():
    """la cible tf-fmt ne vérifie plus le format"""
    in_target("tf-fmt", r"fmt -check -recursive -diff terraform", "version")


def c2():
    """la cible tf-validate ne valide plus"""
    in_target("tf-validate", r"terraform validate", "terraform version")


def c3():
    """le plan exige des identifiants AWS"""
    in_target("plan", r" -e AWS_ACCESS_KEY_ID=offline -e AWS_SECRET_ACCESS_KEY=offline", "")


def c4():
    """le rôle applicatif n'est plus créé"""
    del_block(f"{ENV}/main.tf", r'module "app_role"')
    del_block(f"{ENV}/outputs.tf", r'output "app_role_arn"')


def c5():
    """une ressource payante est ajoutée"""
    append(f"{ENV}/main.tf", '\nresource "aws_eip" "faute" {\n  domain = "vpc"\n}\n')


def c6():
    """fichier de verrouillage des providers absent"""
    remove(f"{ENV}/.terraform.lock.hcl")


def c7():
    """verrou d'état désactivé"""
    resub(f"{ENV}/versions.tf", r"use_lockfile = true", "use_lockfile = false")


def c8():
    """le job de plan des PR peut demander un jeton cloud"""
    in_job(PLAN, "plan", r"(      contents: read\n)", r"\1      id-token: write\n")
