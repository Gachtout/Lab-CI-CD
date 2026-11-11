"""Mutants de l'étape 11 : une contrainte retirée par mutant."""
from mut import MK, WF, in_job, in_target, resub


def c1():
    """inventaire produit dans un autre format"""
    in_target("sbom", r"--format cyclonedx", "--format spdx-json")


def c2():
    """le scan de l'inventaire ne bloque plus"""
    in_target("sbom-scan", r" \$\(TRIVY_GATE\)", "")


def c3():
    """image Prowler sans digest"""
    resub(MK, r"^(PROWLER_IMAGE\s+:= [^@\n]*)@sha256:[0-9a-f]{64}", r"\1")


def c4():
    """inventaire aussi produit sur les pull requests"""
    in_job(WF, "sbom", r"\n    if: [^\n]*", "")
