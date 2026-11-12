#!/usr/bin/env bash
# Banc de test des vérifications du parcours. Vit sur la branche `banc`, jamais sur `exercices`.
#
# Lit le squelette et ses vérifications depuis la branche `exercices`, le corrigé depuis `solution` :
#   - chaque vérification passe sur le corrigé, échoue sur le squelette ;
#   - elle échoue sur CHAQUE mutant, en citant la contrainte retirée ;
#   - progression : avec les étapes 1 à N résolues, N passe et N+1 échoue ;
#   - cohérence page / contrôle / mutant ;
#   - fuite : aucun fragment du corrigé sur la branche d'exercices.
#
# Variables : EXERCICES_REF, SOLUTION_REF (défaut origin/...), ou EXERCICES_DIR, SOLUTION_DIR ;
#             STEPS="01 02", PARTS="mutants progression statique", REPO=<clone à interroger>.
set -uo pipefail

BANC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${BANC}"
REPO=${REPO:-${BANC}}
STEPS=${STEPS:-01 02 03 04 05 06 07 08 09 10 11}
PARTS=${PARTS:-mutants progression statique}
export CACHE="${CACHE:-${BANC}/.cache}"
mkdir -p "${CACHE}" reports
WORK=$(mktemp -d)
trap 'rm -rf -- "${WORK}"' EXIT
status=0

fetch() { # fetch <dossier fourni ou vide> <référence> <destination>
  if [ -n "$1" ]; then echo "$1"; return; fi
  mkdir -p "$3"
  git -C "${REPO}" archive "$2" | tar -x -C "$3" || { echo "Référence introuvable : $2 (git fetch origin)" >&2; exit 2; }
  echo "$3"
}
sk=$(fetch "${EXERCICES_DIR:-}" "${EXERCICES_REF:-origin/exercices}" "${WORK}/exercices") || exit 2
sol=$(fetch "${SOLUTION_DIR:-}" "${SOLUTION_REF:-origin/solution}" "${WORK}/solution") || exit 2

verdict() { # verdict <attendu> <obtenu> <libellé>
  if [ "$1" = "$2" ]; then printf '  PASS  %s\n' "$3"; else printf '  FAIL  %s (attendu : %s, obtenu : %s)\n' "$3" "$1" "$2"; status=1; fi
}
outcome() { if CHECK_FAIL_FAST=1 make -s --no-print-directory -C "$1" "check-etape-$2" > "${WORK}/out" 2>&1; then echo passe; else echo echoue; fi; }
copy() { mkdir -p "$2" && tar -C "$1" --exclude=./.cache --exclude=./reports --exclude=./.git -cf - . | tar -C "$2" -xf - && git -C "$2" init -q -b main; }
build_slice() { python3 tools/slice.py "${sk}" "${sol}" "$1" "$2" && git -C "$2" init -q -b main; }

full="${WORK}/full"
build_slice 11 "${full}"

if [[ " ${PARTS} " == *" mutants "* ]]; then
  for n in ${STEPS}; do
    echo "== Étape ${n}"
    verdict passe "$(outcome "${full}" "${n}")" "corrigé"
    grep -E 'ECHEC' "${WORK}/out" | sed 's/^/        /'
    s="${WORK}/skeleton-${n}"; copy "${sk}" "${s}"
    verdict echoue "$(outcome "${s}" "${n}")" "squelette"
    rm -rf -- "${s}"
    while read -r id doc; do
      [ -n "${id}" ] || continue
      m="${WORK}/mutant-${n}-${id}"; copy "${full}" "${m}"
      if ! python3 tools/mut.py apply "${n}" "${id}" "${m}" > "${WORK}/mut.log" 2>&1; then
        printf '  FAIL  mutant %s : %s\n' "${id}" "$(tail -n 1 "${WORK}/mut.log")"; status=1; continue
      fi
      if diff -rq -x .git "${full}" "${m}" > /dev/null; then
        printf '  FAIL  mutant %s : aucune différence avec le corrigé\n' "${id}"; status=1; continue
      fi
      got=$(outcome "${m}" "${n}")
      c=${id#c}; c=${c%%[a-z]}
      if [ "${got}" = "echoue" ] && grep -q "ECHEC  \[C${c}\]" "${WORK}/out"; then
        printf '  PASS  mutant %-4s détecté par C%-2s  %s\n' "${id}" "${c}" "${doc}"
      else
        printf '  FAIL  mutant %-4s non détecté par C%s (%s)  %s\n' "${id}" "${c}" "${got}" "${doc}"; status=1
        grep -E 'ECHEC' "${WORK}/out" | head -n 3 | sed 's/^/        /'
      fi
      rm -rf -- "${m}"
    done < <(python3 tools/mut.py list "${n}")
  done
fi

if [[ " ${PARTS} " == *" progression "* ]]; then
  echo "== Progression : étapes 1 à N résolues"
  for n in 1 2 3 4 5 6 7 8 9 10; do
    cur=$(printf '%02d' "${n}"); nxt=$(printf '%02d' $((n + 1)))
    s="${WORK}/slice-${n}"
    build_slice "${n}" "${s}"
    got=$(outcome "${s}" "${cur}")
    verdict passe "${got}" "N=${n} : check-etape-${cur} passe"
    [ "${got}" = passe ] || grep -E 'ECHEC' "${WORK}/out" | head -n 3 | sed 's/^/        /'
    verdict echoue "$(outcome "${s}" "${nxt}")" "N=${n} : check-etape-${nxt} échoue"
    rm -rf -- "${s}"
  done
fi

if [[ " ${PARTS} " == *" statique "* ]]; then
  echo "== Cohérence page / contrôle / mutant"
  python3 tools/coherence.py "${sk}" reports/correspondance.md || status=1
  echo "== Fuite du corrigé sur la branche d'exercices"
  python3 tools/leak.py "${sol}" "${sk}" reports/fuites.md || status=1
  echo "== Outillage de mainteneur absent de la branche d'exercices"
  extra=$(cd "${sk}" && { ls -d checks/mutants checks/tools checks/RAPPORT-VALIDATION.md 2>/dev/null; grep -l 'test-checks' Makefile checks/checks.mk README.md 2>/dev/null; })
  if [ -z "${extra}" ]; then echo "  PASS  aucun fichier ni cible de mainteneur"; else echo "  FAIL  présent sur exercices : ${extra}"; status=1; fi
fi

echo
if [ "${status}" -eq 0 ]; then echo "test-checks : TOUT EST VERT"; else echo "test-checks : AU MOINS UN ÉCHEC"; fi
exit "${status}"
