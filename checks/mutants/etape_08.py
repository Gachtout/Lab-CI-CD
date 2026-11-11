"""Mutants de l'étape 8 : une contrainte retirée par mutant."""
from mut import MK, WF, in_job, in_target, resub


def c1():
    """le job exceptions ne vérifie plus rien"""
    in_job(WF, "exceptions", r"run: make exceptions", "run: echo exceptions")


def c2():
    """la cible exceptions accepte tout"""
    in_target("exceptions", r"scripts/check-exceptions\.sh", "true")


def c3():
    """seuil par défaut abaissé"""
    resub(MK, r"^(TRIVY_SEVERITY\s+\?= )HIGH,CRITICAL", r"\1CRITICAL")


def c4():
    """le verdict peut être sauté"""
    in_job(WF, "security-gate", r"\n    if: always\(\)", "")


def c5():
    """un contrôle n'est plus un prérequis du verdict"""
    in_job(WF, "security-gate", r", iac,", ",")


def c6():
    """le verdict ne reçoit plus le résultat des jobs"""
    in_target("summary", r" -e NEEDS_JSON", "")


def c7():
    """le scan global ne renvoie plus d'échec"""
    in_target("scan", r"scripts/scan-all\.sh", "scripts/scan-all.sh || true")


def c8():
    """droit de commenter la PR retiré"""
    in_job(WF, "security-gate", r"\n      pull-requests: write[^\n]*", "")


def c9():
    """titre de la PR inséré dans un script"""
    in_job(WF, "security-gate", r"run: make summary", 'run: echo "${{ github.event.pull_request.title }}" && make summary')
