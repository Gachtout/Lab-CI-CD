#!/usr/bin/env python3
"""Vérifie que chaque contrainte numérotée d'une page a un contrôle et un mutant.

Sources : les lignes "N. texte" de la section « Contraintes » de chaque page, les
identifiants [Cn] / appels (ok|ko|passes|blocks|structure|grep_has...) du script de
vérification, et les fonctions cN des mutants. Sort un tableau Markdown.
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mut  # noqa: E402

# Usage : coherence.py <dossier des exercices> <rapport.md>
exo, report = sys.argv[1], os.path.abspath(sys.argv[2])
os.chdir(exo)

bad = 0
rows = []
for page in sorted(glob.glob("docs/etapes/[0-9][0-9]-*.md")):
    step = os.path.basename(page)[:2]
    text = open(page, encoding="utf-8").read()
    section = re.search(r"(?ms)^Contraintes :\n\n(.*?)(?=^## )", text)
    constraints = re.findall(r"(?m)^(\d+)\. (.+)$", section.group(1)) if section else []
    script = open(f"checks/etape-{step}.sh", encoding="utf-8").read()
    controls = {}
    labels = {"structure": "structure (Rego)", "grep_has": "lecture du fichier", "grep_hasnt": "lecture du fichier",
              "passes": "comportement : doit réussir", "blocks": "comportement : doit échouer",
              "need_file": "présence du fichier", "need_report": "présence du rapport", "ok": "contrôle scripté", "ko": "contrôle scripté"}
    for line in script.split("\n"):
        line = line.strip()
        if line.startswith("#"):
            continue
        found = []
        m = re.search(r"\bstructure\s+\S+\s+\S+((?:\s+\d{1,2})+)\s*$", line)
        if m:
            found += [("structure", cid) for cid in m.group(1).split()]
        for kind, cid in re.findall(r"\b(grep_has|grep_hasnt|passes|blocks|need_file|need_report|ok|ko)\s+\"?(\d{1,2})\"?(?=\s|;|$)", line):
            found.append((kind, cid))
        for kind, cid in found:
            controls.setdefault(cid, [])
            if labels[kind] not in controls[cid]:
                controls[cid].append(labels[kind])
    mutants = mut.load(step)
    by_c = {}
    for name, fn in mutants.items():
        by_c.setdefault(re.sub(r"\D", "", name), []).append(f"`{name}` {(fn.__doc__ or '').strip()}")
    if not constraints:
        print(f"  FAIL  étape {step} : aucune contrainte numérotée trouvée dans {page}")
        bad += 1
    for cid, label in constraints:
        ctl, mu = controls.get(cid), by_c.get(cid)
        if not ctl or not mu:
            bad += 1
        rows.append((step, cid, label, " + ".join(ctl) if ctl else "**MANQUANT**", " ; ".join(mu) if mu else "**MANQUANT**"))
    for cid in sorted(set(by_c) - {c for c, _ in constraints}, key=int):
        print(f"  FAIL  étape {step} : mutant c{cid} sans contrainte correspondante dans la page")
        bad += 1

os.makedirs(os.path.dirname(report), exist_ok=True)
with open(report, "w", encoding="utf-8") as handle:
    handle.write("| Étape | Contrainte | Énoncé | Contrôle | Mutant |\n|---|---|---|---|---|\n")
    for step, cid, label, ctl, mu in rows:
        handle.write(f"| {step} | C{cid} | {label[:70]}{'…' if len(label) > 70 else ''} | {ctl} | {mu} |\n")
print(f"  {'PASS' if bad == 0 else 'FAIL'}  {len(rows)} contraintes, {bad} sans contrôle ou sans mutant")
sys.exit(1 if bad else 0)
