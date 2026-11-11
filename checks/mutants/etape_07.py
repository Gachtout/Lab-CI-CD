"""Mutants de l'étape 7 : une contrainte retirée par mutant."""
from mut import PLAN, append, in_job, in_target, remove, resub

POL = "policies"


def c1():
    """Trivy config ne bloque plus"""
    in_target("iac-trivy", r" --exit-code 1", "")


def c2():
    """Checkov ne bloque plus"""
    append(".checkov.yaml", "soft-fail: true\n")


def c3():
    """policy trop stricte : elle refuse un plan conforme"""
    resub(f"{POL}/tags.rego", r'"ManagedBy"\}', '"ManagedBy", "CostCenter"}')


def c4():
    """policy S3 neutralisée"""
    resub(f"{POL}/s3.rego", r"!= true", '== "jamais"')


def c5():
    """policy réseau neutralisée"""
    resub(f"{POL}/reseau.rego", r"monde := \{[^}]*\}", 'monde := {"203.0.113.0/24"}')


def c6():
    """un tag obligatoire n'est plus exigé"""
    resub(f"{POL}/tags.rego", r'"Owner", ', "")


def c7():
    """un type de ressource payante n'est plus interdit"""
    resub(f"{POL}/cout.rego", r'^\t"aws_nat_gateway":[^\n]*\n', "")


def c8():
    """tests unitaires des policies supprimés"""
    remove(f"{POL}/policies_test.rego")


def c9():
    """le résultat des policies n'est plus pris en compte"""
    in_target("policy", r"\| tee \$\(REPORTS\)/policy\.txt", "| tee $(REPORTS)/policy.txt || true")


def c10():
    """le workflow de PR ne lance plus les policies"""
    in_job(PLAN, "plan", r"run: make policy", "run: make plan")
