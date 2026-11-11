"""Mutants de l'étape 3 : une contrainte retirée par mutant."""
from mut import MK, WF, in_job, in_target, resub

CONF = ".gitleaks.toml"


def c1():
    """règles par défaut désactivées"""
    resub(CONF, r"useDefault = true", "useDefault = false")


def c2():
    """règle maison qui ne reconnaît plus le format du lab"""
    resub(CONF, r"LABFAKE_", "LABFAUX_")


def c3():
    """scan du répertoire courant au lieu de l'historique"""
    in_target("secrets", r" git --report-format", " dir --report-format")


def c4():
    """rapport écrit ailleurs qu'à l'emplacement imposé"""
    in_target("secrets", r"gitleaks\.sarif", "fuites.sarif")


def c5():
    """la cible du hook ne regarde plus les fichiers indexés"""
    in_target("secrets-staged", r" --pre-commit --staged", "")


def c6():
    """le hook appelle le scan d'historique"""
    resub(".pre-commit-config.yaml", r"make secrets-staged", "make secrets")


def c7():
    """historique tronqué dans le job"""
    in_job(WF, "secrets", r"fetch-depth: 0", "fetch-depth: 1")


def c8():
    """secrets affichés en clair"""
    resub(MK, r" --redact", "")
