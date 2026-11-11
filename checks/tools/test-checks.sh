#!/usr/bin/env bash
# Banc de test des vérifications (outil de mainteneur).
# Pour chaque étape : la vérification passe sur le corrigé, échoue sur le squelette,
# et échoue sur CHAQUE mutant en citant la contrainte retirée. Puis : progression,
# cohérence page / contrôle / mutant, et recherche de fuite du corrigé.
#
# Le corrigé est lu depuis la branche `solution` (SOLUTION_REF) ou un dossier (SOLUTION_DIR).
# Variables : STEPS="01 02" pour limiter les étapes, PARTS="mutants progression statique".
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "${ROOT}"
STEPS=${STEPS:-01 02 03 04 05 06 07 08 09 10 11}
PARTS=${PARTS:-mutants progression statique}
export CACHE="${CACHE:-${ROOT}/.cache}"
WORK=$(mktemp -d)
trap 'rm -rf -- "${WORK}"' EXIT
status=0

if [ -n "${SOLUTION_DIR:-}" ]; then
  sol="${SOLUTION_DIR}"
else
  sol="${WORK}/solution"
  mkdir -p "${sol}"
  git archive "${SOLUTION_REF:-origin/solution}" | tar -x -C "${sol}" || { echo "Branche solution introuvable : fais git fetch origin solution."; exit 2; }
fi

verdict() { # verdict <attendu> <obtenu> <libellé>
  if [ "$1" = "$2" ]; then printf '  PASS  %s\n' "$3"; else printf '  FAIL  %s (attendu : %s, obtenu : %s)\n' "$3" "$1" "$2"; status=1; fi
}
run_check() { # run_check <dossier> <étape> : code de sortie de la vérification, sortie dans $WORK/out
  CHECK_FAIL_FAST=1 make -s --no-print-directory -C "$1" "check-etape-$2" > "${WORK}/out" 2>&1
}
outcome() { if run_check "$1" "$2"; then echo passe; else echo echoue; fi; }
copy() { mkdir -p "$2" && tar -C "$1" --exclude=./.cache --exclude=./reports --exclude=./.git -cf - . | tar -C "$2" -xf - && git -C "$2" init -q -b main; }
build_slice() { python3 checks/tools/slice.py "${ROOT}" "${sol}" "$1" "$2" && git -C "$2" init -q -b main; }

full="${WORK}/full"
build_slice 11 "${full}"

if [[ " ${PARTS} " == *" mutants "* ]]; then
  for n in ${STEPS}; do
    echo "== Étape ${n}"
    verdict passe "$(outcome "${full}" "${n}")" "corrigé"
    [ -s "${WORK}/out" ] && grep -E 'ECHEC' "${WORK}/out" | sed 's/^/        /'
    sk="${WORK}/skeleton-${n}"; copy "${ROOT}" "${sk}"
    verdict echoue "$(outcome "${sk}" "${n}")" "squelette"
    while read -r id doc; do
      [ -n "${id}" ] || continue
      m="${WORK}/mutant-${n}-${id}"; copy "${full}" "${m}"
      if ! python3 checks/tools/mut.py apply "${n}" "${id}" "${m}" > "${WORK}/mut.log" 2>&1; then
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
    done < <(python3 checks/tools/mut.py list "${n}")
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
  python3 checks/tools/coherence.py || status=1
  echo "== Fuite du corrigé"
  python3 checks/tools/leak.py "${sol}" || status=1
fi

echo
if [ "${status}" -eq 0 ]; then echo "test-checks : TOUT EST VERT"; else echo "test-checks : AU MOINS UN ÉCHEC"; fi
exit "${status}"
