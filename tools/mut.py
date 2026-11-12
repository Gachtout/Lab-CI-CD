"""Outils de mutation : chaque mutant retire UNE contrainte du corrigé.

Un mutant est une transformation (expression régulière, édition JSON), jamais un
fichier complet : la version correcte d'un livrable n'est pas stockée ici.
"""
import importlib.util
import json
import os
import re
import sys

WF = ".github/workflows/pr-security.yml"
PLAN = ".github/workflows/terraform-plan.yml"
DEPLOY = ".github/workflows/deploy.yml"
DESTROY = ".github/workflows/destroy.yml"
MK = "Makefile"


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def write(path, text):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


def resub(path, pattern, repl, count=1, flags=re.M):
    """Remplace ; échoue si rien n'a changé (un mutant sans effet ne prouve rien)."""
    text = read(path)
    new, done = re.subn(pattern, repl, text, count=count, flags=flags)
    if done == 0 or new == text:
        raise SystemExit(f"mutant sans effet : {pattern!r} dans {path}")
    write(path, new)


def job_span(text, job):
    """Bornes du bloc d'un job : son en-tête puis les lignes vides ou indentées d'au moins 4 espaces."""
    match = re.search(rf"(?m)^  {re.escape(job)}:\n(?:(?:    [^\n]*)?\n)*", text)
    if match is None:
        raise SystemExit(f"job introuvable : {job}")
    return match.start(), match.end()


def in_job(path, job, pattern, repl, count=1):
    """Même chose, limité au bloc d'un job de workflow."""
    text = read(path)
    start, end = job_span(text, job)
    block, done = re.subn(pattern, repl, text[start:end], count=count, flags=re.M)
    if done == 0:
        raise SystemExit(f"mutant sans effet : {pattern!r} dans le job {job}")
    write(path, text[:start] + block + text[end:])


def in_target(target, pattern, repl):
    """Même chose, limité à la recette d'une cible du Makefile."""
    text = read(MK)
    match = re.search(rf"(?ms)^{re.escape(target)}:[^\n]*\n(?:\t[^\n]*\n)+", text)
    if match is None:
        raise SystemExit(f"cible introuvable : {target}")
    block, done = re.subn(pattern, repl, match.group(0), flags=re.M)
    if done == 0:
        raise SystemExit(f"mutant sans effet : {pattern!r} dans la cible {target}")
    write(MK, text[: match.start()] + block + text[match.end():])


def del_block(path, start_pattern):
    """Supprime un bloc HCL ou Rego : de l'en-tête jusqu'à l'accolade fermante en colonne 0."""
    resub(path, rf"(?ms)^{start_pattern}.*?^\}}\n", "")


def json_edit(path, fn):
    data = json.loads(read(path))
    fn(data)
    write(path, json.dumps(data, indent=2) + "\n")


def append(path, text):
    write(path, (read(path) if os.path.exists(path) else "") + text)


def remove(path):
    os.remove(path)


def load(step):
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "..", "mutants", f"etape_{step}.py")
    spec = importlib.util.spec_from_file_location(f"etape_{step}", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return {name: fn for name, fn in vars(module).items() if re.fullmatch(r"c\d+[a-z]?", name) and callable(fn)}


if __name__ == "__main__":
    # mut.py list <étape>            : identifiants des mutants
    # mut.py apply <étape> <id> <dossier> : applique un mutant dans une copie du corrigé
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    mutants = load(sys.argv[2])
    if sys.argv[1] == "list":
        for name in sorted(mutants, key=lambda n: (int(re.sub(r"\D", "", n)), n)):
            print(name, (mutants[name].__doc__ or "").strip())
    else:
        os.chdir(sys.argv[4])
        mutants[sys.argv[3]]()
