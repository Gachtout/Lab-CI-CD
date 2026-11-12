#!/usr/bin/env python3
"""Cherche des fragments du corrigé sur la branche d'exercices, et classe chaque occurrence.

Usage : leak.py <corrigé> <exercices> <rapport.md>

Deux recherches :
  1. lignes entières (au moins 30 caractères) des livrables du corrigé ;
  2. littéraux d'au moins 12 caractères extraits de ces livrables : chaînes entre guillemets,
     options de commande avec leur valeur, valeurs YAML, jetons contenant de la ponctuation
     technique ; plus les noms de fichiers propres au corrigé.
Le texte des exercices est aussi comparé après dés-échappement des expressions régulières.

Classement de chaque occurrence :
  - « faute injectée » ou « donnée d'entrée » : fichiers de checks/faults/ et checks/fixtures/ ;
  - « énoncé / contrat » : le littéral figure, entre accents graves, dans l'énoncé ou le contrat
    d'interface d'une page : il est imposé à l'apprenant, donc divulgué volontairement ;
  - « nécessaire au check » : couvert par une entrée justifiée de tools/leak-allow.tsv,
    et seulement dans checks/ ;
  - « FUITE » : tout le reste. Une seule fuite fait échouer l'outil.
"""
import os
import re
import sys

sol, exo, report = sys.argv[1], sys.argv[2], sys.argv[3]
HERE = os.path.dirname(os.path.abspath(__file__))
DELIVERABLES = [
    ".github/workflows", ".github/rulesets", ".gitleaks.toml", ".pre-commit-config.yaml", ".semgrep",
    ".checkov.yaml", ".trivyignore.yaml", "app/Dockerfile", "app/.dockerignore", "policies", "terraform",
    "scripts/setup-github.sh", "Makefile",
]
GENERIC_NAMES = {"main.tf", "variables.tf", "outputs.tf", "versions.tf", "providers.tf", "Makefile", "Dockerfile",
                 ".gitkeep", "main.json"}
MIN_LINE, MIN_LIT = 30, 12
TECH = set("-_./:=@$")


def norm(line):
    return " ".join(line.split())


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except (UnicodeDecodeError, OSError):
        return ""


def walk(root):
    for base, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in (".git", ".cache", "reports", "site")]
        for name in files:
            yield os.path.join(base, name)


def literals(line):
    found = set()
    for a, b in re.findall(r'"([^"\n]{%d,})"|\'([^\'\n]{%d,})\'' % (MIN_LIT, MIN_LIT), line):
        found.add(a or b)
    for opt in re.findall(r"(?<![\w-])(--?[A-Za-z][\w-]*(?:[ =](?!-)[^\s\\]+)?)", line):
        found.add(opt)
        found.add(opt.split(" ")[0].split("=")[0])
    m = re.match(r"^\s*-?\s*[\w.-]+:\s+(\S.*)$", line)
    if m:
        found.add(re.sub(r"\s+#.*$", "", m.group(1)).strip("\"'"))
    for token in line.split():
        token = token.strip("\"'(),;[]{}\\").rstrip(".:=,").strip("\"'(),;[]{}\\")
        if any(ch in TECH for ch in token[1:-1]):
            found.add(token)
    # Noms de clés YAML et d'attributs HCL : ils décrivent la structure du livrable.
    key = re.match(r"^\s*-?\s*([A-Za-z_][\w.-]{%d,}):(\s|$)" % (MIN_LIT - 1), line) or re.match(r"^\s*([a-z_][\w]{%d,})\s*=" % (MIN_LIT - 1), line)
    if key and re.search(r"[_.-]", key.group(1)):
        found.add(key.group(1))
    return {x.strip() for x in found if len(x.strip()) >= MIN_LIT and not x.strip().startswith("#")}


exo_files = sorted(walk(exo))


def rel(path):
    return os.path.relpath(path, exo).replace(os.sep, "/")


# Ce qui est fourni à l'apprenant de toute façon : on ne le cherche pas.
PROVIDED = ("Makefile", ".gitignore", "mkdocs.yml", "LICENSE")
provided_text = "\n".join(read(p) for p in exo_files if rel(p) in PROVIDED or rel(p).startswith(("app/", "scripts/")))
provided_names = {os.path.basename(p) for p in exo_files if rel(p).startswith(("app/", "scripts/"))}
provided_text += "\n" + "\n".join(sorted(provided_names))
provided_lines = {norm(line) for line in provided_text.split("\n")}

needles_line, needles_lit = {}, {}
for item in DELIVERABLES:
    root = os.path.join(sol, item)
    paths = [root] if os.path.isfile(root) else list(walk(root))
    for path in paths:
        origin = os.path.relpath(path, sol)
        name = os.path.basename(path)
        if name.endswith(".lock.hcl"):
            continue
        if name not in GENERIC_NAMES and name not in provided_names and len(name) >= 6:
            needles_lit.setdefault(name, origin)
        for raw in read(path).split("\n"):
            line = norm(raw)
            if not line or line.startswith(("#", "//")):
                continue
            if len(line) >= MIN_LINE and line not in provided_lines:
                needles_line.setdefault(line, origin)
            for lit in literals(raw):
                if lit not in provided_text:
                    needles_lit.setdefault(lit, origin)

# Littéraux imposés par les énoncés, les contrats d'interface et la liste de ce qui est fourni.
contract = set()
for path in exo_files:
    if not rel(path).startswith("docs/etapes/"):
        continue
    text = read(path)
    for title in ("Énoncé", "Contrat d'interface", "Ce qui t'est fourni"):
        m = re.search(rf"(?ms)^## {re.escape(title)}\n(.*?)(?=^## |\Z)", text)
        if m:
            contract.update(span.strip() for span in re.findall(r"`([^`\n]+)`", m.group(1)))


def in_contract(lit):
    return any(lit == span or lit in span or (len(span) >= 8 and span in lit) for span in contract)


allow = []
allow_path = os.path.join(HERE, "leak-allow.tsv")
for row in read(allow_path).split("\n"):
    if row.strip() and not row.startswith("#"):
        pattern, _, why = row.partition("\t")
        allow.append((re.compile(pattern), why.strip()))


def classify(path, lit):
    if path.startswith("checks/faults/"):
        return "faute injectée", "version fautive, jamais la version correcte"
    if path.startswith("checks/fixtures/"):
        return "donnée d'entrée", "plan Terraform de référence fourni à l'étape 7"
    if in_contract(lit):
        return "énoncé / contrat", "nom ou valeur imposé par un énoncé"
    for pattern, why in allow:
        if pattern.search(lit) and (path.startswith("checks/") or why.startswith("[partout]")):
            return "nécessaire au check", why.replace("[partout]", "").strip()
    return "FUITE", "à retirer"


hits = {}
for path in exo_files:
    text = read(path)
    if not text:
        continue
    plain = re.sub(r"\\([^A-Za-z0-9\n])", r"\1", text)
    for number, (a, b) in enumerate(zip(text.split("\n"), plain.split("\n")), 1):
        for candidate in {norm(a), norm(b)}:
            if candidate in needles_line:
                hits.setdefault((candidate, needles_line[candidate]), []).append((rel(path), number))
        for lit, origin in needles_lit.items():
            if lit in a or lit in b:
                hits.setdefault((lit, origin), []).append((rel(path), number))

# Extraits entre accents graves des pages et du README, hors énoncé et contrat : s'ils figurent
# tels quels dans un livrable du corrigé, c'est une fuite, dès 4 caractères s'ils ont une ponctuation technique.
solution_text = "\n".join(read(p) for item in DELIVERABLES for p in ([os.path.join(sol, item)] if os.path.isfile(os.path.join(sol, item)) else walk(os.path.join(sol, item))) if not p.endswith(".lock.hcl"))
for path in exo_files:
    if not (rel(path).startswith("docs/") or rel(path) == "README.md"):
        continue
    for number, line in enumerate(read(path).split("\n"), 1):
        for span in re.findall(r"`([^`\n]{4,})`", line):
            span = span.strip()
            technical = len(span) >= MIN_LIT or any(ch in TECH for ch in span)
            if technical and span in solution_text and span not in provided_text and not in_contract(span):
                hits.setdefault((span, "extrait de code d'une page"), []).append((rel(path), number))

rows, leaks, counts = [], 0, {}
for (lit, origin), where in sorted(hits.items(), key=lambda kv: kv[0][0].lower()):
    by_class = {}
    for path, number in sorted(set(where)):
        by_class.setdefault(classify(path, lit), []).append(f"{path}:{number}")
    for (cls, why), places in sorted(by_class.items()):
        counts[cls] = counts.get(cls, 0) + len(places)
        if cls == "FUITE":
            leaks += len(places)
        rows.append((cls, lit, origin, why, places))

os.makedirs(os.path.dirname(report) or ".", exist_ok=True)
with open(report, "w", encoding="utf-8") as handle:
    handle.write("# Fragments du corrigé présents sur la branche d'exercices\n\n")
    handle.write(f"{len(needles_line)} lignes et {len(needles_lit)} littéraux du corrigé cherchés dans {len(exo_files)} fichiers.\n\n")
    handle.write("| Classe | Occurrences |\n|---|---|\n")
    for cls in sorted(counts):
        handle.write(f"| {cls} | {counts[cls]} |\n")
    for cls in ("FUITE", "nécessaire au check", "énoncé / contrat", "donnée d'entrée", "faute injectée"):
        subset = [r for r in rows if r[0] == cls]
        if not subset:
            continue
        handle.write(f"\n## {cls}\n\n| Fragment | Vient de | Justification | Emplacements |\n|---|---|---|---|\n")
        for _, lit, origin, why, places in subset:
            shown = ", ".join(places[:6]) + (f" … (+{len(places) - 6})" if len(places) > 6 else "")
            handle.write(f"| `{lit[:80].replace('|', '¦')}` | {origin} | {why} | {shown} |\n")

for cls, lit, origin, why, places in rows:
    if cls == "FUITE":
        print(f"  FUITE  {lit[:70]!r} (de {origin}) : {', '.join(places[:4])}")
print("  " + " ; ".join(f"{cls} : {n}" for cls, n in sorted(counts.items())))
print(f"  {'PASS' if leaks == 0 else 'FAIL'}  {len(needles_line)} lignes et {len(needles_lit)} littéraux cherchés dans {len(exo_files)} fichiers, {leaks} fuite(s) (détail : {report})")
sys.exit(1 if leaks else 0)
