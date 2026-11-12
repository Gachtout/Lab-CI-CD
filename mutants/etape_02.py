"""Mutants de l'étape 2 : une contrainte retirée par mutant."""
from mut import WF, in_job, in_target, resub

DF = "app/Dockerfile"


def c1():
    """image de base sans digest"""
    resub(DF, r"@sha256:[0-9a-f]{64}", "")


def c2():
    """exécution en root"""
    resub(DF, r"^USER [^\n]*\n", "")


def c3():
    """contrôle de santé retiré"""
    resub(DF, r"^HEALTHCHECK[^\n]*\\\n[^\n]*\n", "")


def c4():
    """cache pip conservé dans l'image"""
    resub(DF, r" --no-cache-dir", "")


def c5():
    """la cible test ne lance plus les tests"""
    in_target("test", r"-m pytest [^']*", '-c "print(0)"')


def c6():
    """la cible build ignore la variable IMAGE"""
    in_target("build", r"\$\(IMAGE\)", "devsecops-lab-app:fixe")


def c7():
    """le job build-test ne lance plus les tests"""
    in_job(WF, "build-test", r"run: make test", "run: echo test")
