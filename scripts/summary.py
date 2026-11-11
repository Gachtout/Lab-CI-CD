#!/usr/bin/env python3
"""Construit reports/summary.md : verdict de chaque gate et constats des rapports SARIF.

Le verdict vient du résultat des jobs (variable NEEDS_JSON en CI, reports/gates.json en local).
Les constats listés viennent des fichiers SARIF, hors exceptions acceptées.
Code de sortie : 1 si au moins un gate n'est pas en succès.
"""
import glob
import json
import os
import sys

REPORTS = "reports"
MAX_FINDINGS = 10


def load_gates():
    raw = os.environ.get("NEEDS_JSON")
    if raw:
        return json.loads(raw)
    path = os.path.join(REPORTS, "gates.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    return {}


def load_findings():
    findings = {}
    for path in sorted(glob.glob(os.path.join(REPORTS, "**", "*.sarif"), recursive=True)):
        tool = os.path.splitext(os.path.basename(path))[0]
        try:
            with open(path, encoding="utf-8") as handle:
                sarif = json.load(handle)
        except (OSError, json.JSONDecodeError):
            continue
        rows = []
        for run in sarif.get("runs", []):
            for result in run.get("results", []):
                if result.get("suppressions"):
                    continue  # exception acceptée : déjà suivie par make exceptions
                location = "?"
                locations = result.get("locations") or []
                if locations:
                    physical = locations[0].get("physicalLocation", {})
                    uri = physical.get("artifactLocation", {}).get("uri", "?")
                    line = physical.get("region", {}).get("startLine")
                    location = f"{uri}:{line}" if line else uri
                rows.append((result.get("level", "warning"), result.get("ruleId", "?"), location))
        findings[tool] = rows
    return findings


def main():
    gates = load_gates()
    findings = load_findings()
    blocked = [name for name, data in gates.items() if data.get("result") != "success"]

    lines = []
    if not gates:
        lines.append("### Quality gates : aucun résultat disponible")
    elif blocked:
        lines.append(f"### ❌ Quality gates : {len(blocked)} contrôle(s) bloquant(s) sur {len(gates)}")
        lines.append("")
        lines.append("La fusion est bloquée tant que ces contrôles ne sont pas verts.")
    else:
        lines.append(f"### ✅ Quality gates : {len(gates)} contrôles passés")
    lines += ["", "| Contrôle | Verdict |", "|---|---|"]
    for name, data in gates.items():
        result = data.get("result", "?")
        lines.append(f"| `{name}` | {'✅ passe' if result == 'success' else '❌ ' + result} |")

    lines += ["", "<details><summary>Constats présents dans les rapports SARIF</summary>", ""]
    lines.append("Les exceptions acceptées ne sont pas listées. Semgrep liste aussi ses avertissements non bloquants.")
    lines.append("")
    lines += ["| Rapport | Constats |", "|---|---|"]
    for tool, rows in findings.items():
        lines.append(f"| `{tool}` | {len(rows)} |")
    for tool, rows in findings.items():
        if not rows:
            continue
        lines += ["", f"**{tool}**", ""]
        for level, rule, location in rows[:MAX_FINDINGS]:
            lines.append(f"- `{rule}` ({level}) dans `{location}`")
        if len(rows) > MAX_FINDINGS:
            lines.append(f"- … et {len(rows) - MAX_FINDINGS} autre(s)")
    lines += ["", "</details>", ""]

    os.makedirs(REPORTS, exist_ok=True)
    with open(os.path.join(REPORTS, "summary.md"), "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    print("\n".join(lines))
    return 1 if blocked or not gates else 0


if __name__ == "__main__":
    sys.exit(main())
