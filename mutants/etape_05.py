"""Mutants de l'étape 5 : une contrainte retirée par mutant."""
from mut import MK, WF, in_job, in_target, resub


def c1():
    """outil d'installation laissé dans l'image"""
    resub("app/Dockerfile", r" \\\n && pip uninstall[^\n]*", "")


def c2():
    """le scan d'image ne bloque plus"""
    in_target("image-scan", r"\$\(TRIVY_GATE\)", "--severity $(TRIVY_SEVERITY)")


def c3():
    """socket Docker monté dans le scanner"""
    resub(MK, r"^TRIVY := \$\(RUN\) ", "TRIVY := $(RUN) -v /var/run/docker.sock:/var/run/docker.sock ")


def c4():
    """configuration de l'image non analysée"""
    in_target("image-scan", r" --image-config-scanners misconfig,secret", "")


def c5():
    """rapport d'image écrit ailleurs qu'à l'emplacement imposé"""
    in_target("image-scan", r"trivy-image\.sarif", "image.sarif")


def c6():
    """le job image ne scanne plus"""
    in_job(WF, "image", r"run: make image-scan", "run: echo scan")
