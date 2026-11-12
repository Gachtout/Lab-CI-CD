"""Mutants de l'étape 1 : une contrainte retirée par mutant."""
from mut import MK, WF, in_job, resub


def c1():
    """déclenchement manuel retiré"""
    resub(WF, r"\n  workflow_dispatch:\n", "\n")


def c2():
    """droits par défaut rendus au jeton"""
    resub(WF, r"^permissions: \{\}", "permissions: write-all")


def c3():
    """une action épinglée par tag"""
    resub(WF, r"@[0-9a-f]{40}", "@v7")


def c4():
    """persistance du jeton réactivée"""
    in_job(WF, "workflow-lint", r"persist-credentials: false", "persist-credentials: true")


def c5():
    """le job n'appelle plus make"""
    in_job(WF, "workflow-lint", r"run: make lint-workflows", "run: echo lint")


def c6():
    """artifact non publié en cas d'échec"""
    in_job(WF, "workflow-lint", r"\n        if: always\(\)", "")


def c7():
    """durée maximale retirée"""
    in_job(WF, "workflow-lint", r"\n    timeout-minutes: \d+", "")


def c8():
    """annulation de l'exécution précédente retirée"""
    resub(WF, r"cancel-in-progress: true", "cancel-in-progress: false")


def c9():
    """pipefail retiré : le tube masque l'échec"""
    resub(MK, r" -o pipefail", "")
