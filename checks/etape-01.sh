#!/usr/bin/env bash
# Vérification de l'étape 1 : pipeline minimal.
source "$(dirname "$0")/lib.sh"
WF=.github/workflows/pr-security.yml

structure e01.workflow "${WF}" 1 2 3 4 5 6 7 8
stage

if is_stub lint-workflows; then
  ko 9 "cible lint-workflows non implémentée ($(loc Makefile 'lint-workflows:'))"
else
  d0=$(sandbox)
  passes 9 "lint de tes workflows" "${d0}" lint-workflows
  d=$(sandbox)
  cp checks/faults/etape-01/workflow-faux.faute "${d}/.github/workflows/zz-faux.yml"
  blocks 9 "lint d'un workflow volontairement faux" "${d}" lint-workflows
  if [ ! -f "${d}/reports/actionlint.txt" ]; then ko 9 "rapport attendu absent : reports/actionlint.txt"; fi
fi
finish
