"""Mutants de l'étape 4 : une contrainte retirée par mutant."""
from mut import MK, WF, in_target, resub

RULES = ".semgrep/regles-maison.yml"


def c1():
    """jeux de règles communautaires retirés"""
    resub(MK, r" --config p/python --config p/flask", "")


def c2():
    """règle maison sur les secrets de configuration retirée"""
    resub(RULES, r"(?ms)^  - id: interdit-secret-en-dur.*\Z", "")


def c3():
    """règle maison sur le mode debug retirée"""
    resub(RULES, r"(?ms)^  - id: interdit-flask-debug.*?(?=^  - id:)", "")


def c4():
    """le SAST bloque sur toutes les sévérités"""
    in_target("sast", r" --severity \$\(SEMGREP_SEVERITY\)", "")


def c5():
    """la cible sca ne bloque plus"""
    in_target("sca", r"fs --scanners vuln \$\(TRIVY_GATE\) app", "fs --scanners vuln app")


def c6():
    """seuil écrit en dur au lieu d'être piloté par la variable"""
    resub(MK, r"^(TRIVY_GATE := --severity )\$\(TRIVY_SEVERITY\)", r"\1HIGH,CRITICAL")


def c7():
    """rapport SAST écrit ailleurs qu'à l'emplacement imposé"""
    in_target("sast", r"semgrep\.sarif", "sast.sarif")


def c8():
    """l'envoi du rapport peut faire échouer un job"""
    resub(WF, r"\n        continue-on-error: true", "")
