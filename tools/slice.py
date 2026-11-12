#!/usr/bin/env python3
"""Reconstitue un dépôt où seules les étapes 1 à N sont résolues.

Usage : slice.py <squelette> <corrigé> <N> <sortie>

Sert au banc de test (make test-checks) : le corrigé n'est jamais stocké sur la
branche d'exercices, il est lu depuis la branche `solution` au moment du test.
"""
import os
import re
import shutil
import sys

# Premier numéro d'étape auquel un fichier ou dossier du corrigé appartient.
FILES = {
    "app/Dockerfile": 2, "app/.dockerignore": 2,
    ".gitleaks.toml": 3, ".pre-commit-config.yaml": 3,
    ".semgrep": 4,
    "terraform/modules": 6, "terraform/envs": 6, ".github/workflows/terraform-plan.yml": 6,
    "policies": 7, ".checkov.yaml": 7, ".trivyignore.yaml": 7,
    "scripts/demo.sh": 8, "demo": 8,
    ".github/rulesets": 9, "scripts/setup-github.sh": 9,
    "terraform/bootstrap": 10, ".github/workflows/deploy.yml": 10, ".github/workflows/destroy.yml": 10,
}
JOBS = {
    "workflow-lint": 1, "build-test": 2, "secrets": 3, "sast": 4, "sca": 4, "image": 5,
    "iac": 7, "exceptions": 8, "gates-selftest": 8, "security-gate": 8, "sbom": 11,
}
BANNER = re.compile(r"^# Étape (\d+)\b")
TAIL = "# === Vérifications du parcours"


def sections(text):
    """Découpe un Makefile en (préambule, {étape: bloc}, queue)."""
    lines = text.split("\n")
    starts = [(i - 1, int(BANNER.match(line).group(1))) for i, line in enumerate(lines) if BANNER.match(line)]
    tail_at = next((i for i, line in enumerate(lines) if line.startswith(TAIL)), len(lines))
    pre = "\n".join(lines[: starts[0][0]])
    blocks = {}
    for k, (start, step) in enumerate(starts):
        end = starts[k + 1][0] if k + 1 < len(starts) else tail_at
        blocks[step] = "\n".join(lines[start:end])
    return pre, blocks, "\n".join(lines[tail_at:])


def slice_jobs(text, upto):
    """Retire d'un workflow les jobs appartenant à une étape postérieure."""
    head, _, body = text.partition("\njobs:\n")
    kept, block, name = [], [], None
    for line in body.split("\n"):
        header = re.match(r"^  ([a-z0-9-]+):$", line)
        comment = line.startswith("  #")
        if header or (comment and name is not None):
            if name is None or JOBS.get(name, 0) <= upto:
                kept.extend(block)
            block, name = [], (header.group(1) if header else "")
        if header:
            name = header.group(1)
        block.append(line)
    if name is None or JOBS.get(name, 0) <= upto:
        kept.extend(block)
    return head + "\njobs:\n" + "\n".join(kept).rstrip("\n") + "\n"


def main():
    skeleton, solution, upto, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    ignore = shutil.ignore_patterns(".git", ".cache", "reports", "site")
    shutil.copytree(skeleton, out, ignore=ignore, dirs_exist_ok=True)

    for path, step in FILES.items():
        src = os.path.join(solution, path)
        if step > upto or not os.path.exists(src):
            continue
        dst = os.path.join(out, path)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)

    sol_pre, sol_blocks, _ = sections(open(os.path.join(solution, "Makefile"), encoding="utf-8").read())
    _, sk_blocks, sk_tail = sections(open(os.path.join(skeleton, "Makefile"), encoding="utf-8").read())
    parts = [sol_pre]
    for step in sorted(sol_blocks):
        parts.append(sol_blocks[step] if step <= upto else sk_blocks[step])
    parts.append(sk_tail)
    with open(os.path.join(out, "Makefile"), "w", encoding="utf-8") as handle:
        handle.write("\n".join(parts))

    if upto >= 1:
        workflow = open(os.path.join(solution, ".github/workflows/pr-security.yml"), encoding="utf-8").read()
        dst = os.path.join(out, ".github/workflows/pr-security.yml")
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w", encoding="utf-8") as handle:
            handle.write(slice_jobs(workflow, upto))

    # Accommodement du banc de test : le corrigé final valide aussi terraform/bootstrap,
    # qui n'existe qu'à partir de l'étape 10. Un dossier vide est valide pour Terraform.
    if 6 <= upto < 10:
        os.makedirs(os.path.join(out, "terraform/bootstrap"), exist_ok=True)


if __name__ == "__main__":
    main()
