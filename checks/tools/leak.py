#!/usr/bin/env python3
"""Cherche dans la branche d'exercices des lignes du corrigé.

Usage : leak.py <dossier du corrigé>

On prend chaque ligne significative des livrables du corrigé (ce que l'apprenant doit
écrire) et on la cherche à l'identique dans tous les fichiers suivis de l'arbre courant.
Une ligne est significative si elle fait au moins 30 caractères une fois épurée et
n'est ni un commentaire ni une ligne partagée avec les fichiers fournis.
"""
import os
import subprocess
import sys

sol = sys.argv[1]
DELIVERABLES = [
    ".github/workflows", ".github/rulesets", ".gitleaks.toml", ".pre-commit-config.yaml", ".semgrep",
    ".checkov.yaml", ".trivyignore.yaml", "app/Dockerfile", "policies", "terraform", "demo",
    "scripts/demo.sh", "scripts/setup-github.sh", "Makefile",
]
MIN = 30


def norm(line):
    return " ".join(line.split())


def lines_of(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return [norm(line) for line in handle]
    except (UnicodeDecodeError, OSError):
        return []


tracked = subprocess.run(["git", "ls-files", "-co", "--exclude-standard"], capture_output=True, text=True).stdout.split("\n")
tracked = [p for p in tracked if p and os.path.isfile(p)]

# Lignes légitimement communes : plomberie fournie du Makefile et fichiers fournis.
provided = set()
for path in tracked:
    if path == "Makefile" or path.startswith(("app/", "scripts/")):
        provided.update(lines_of(path))

needles = {}
for item in DELIVERABLES:
    root = os.path.join(sol, item)
    paths = [root] if os.path.isfile(root) else [os.path.join(d, f) for d, _, fs in os.walk(root) for f in fs]
    for path in paths:
        if path.endswith(".lock.hcl"):
            continue
        for line in lines_of(path):
            if len(line) < MIN or line.startswith(("#", "//")) or line in provided:
                continue
            needles.setdefault(line, os.path.relpath(path, sol))

hits = []
for path in tracked:
    for number, line in enumerate(lines_of(path), 1):
        if line in needles:
            hits.append((path, number, needles[line], line))

for path, number, origin, line in hits[:40]:
    print(f"  FAIL  {path}:{number} reprend une ligne de {origin} : {line[:90]}")
print(f"  {'PASS' if not hits else 'FAIL'}  {len(needles)} lignes du corrigé cherchées dans {len(tracked)} fichiers, {len(hits)} occurrence(s)")
sys.exit(1 if hits else 0)
