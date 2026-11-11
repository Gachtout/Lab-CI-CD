#!/usr/bin/env bash
# Démonstration rouge / vert du blocage.
#   demo.sh good    : lance tous les gates sur le dépôt courant ; attendu : tout passe
#   demo.sh bad     : applique demo/bad.patch + un secret factice dans une COPIE temporaire,
#                     lance tous les gates ; attendu : chaque contrôle visé bloque
#   demo.sh branch  : crée la branche demo/bad dans ce dépôt, prête à pousser pour ouvrir la PR "bad"
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "${root}"

# Le secret factice est assemblé ici pour ne figurer en clair nulle part dans le dépôt sain.
fake_token="LABFAKE_""7Q2M9X4K1Z8W3R6T5Y0B2N4C"
expected_blocked="tests secrets sast sca image iac-trivy iac-checkov policy"
expected_passing="exceptions"

inject() {
  git apply demo/bad.patch
  printf '# DEMO : secret factice, format fictif du lab.\nAPI_TOKEN = "%s"\n' "${fake_token}" > app/config_local.py
}

result_of() { grep -o "\"$1\": {\"result\": \"[a-z]*\"" reports/gates.json | sed 's/.*"\([a-z]*\)"$/\1/'; }

case "${1:-}" in
  good)
    scripts/scan-all.sh && printf '\n\033[32mDémo good : tous les contrôles passent, la fusion serait autorisée.\033[0m\n'
    ;;

  bad)
    work=$(mktemp -d)
    trap 'rm -rf "${work}"' EXIT
    git clone --quiet . "${work}/repo"
    if ! git diff --quiet HEAD; then
      echo "Note : la démo part du dernier commit ; tes modifications non commitées sont ignorées."
    fi
    (
      cd "${work}/repo"
      inject
      git add -A
      git -c user.name=demo -c user.email=demo@lab.invalid commit --quiet --no-verify -m "demo: changements vulnérables"
      # Même cache que le dépôt d'origine (base Trivy, providers), image sous un autre nom.
      CACHE="${CACHE:-${root}/.cache}" IMAGE=devsecops-lab-app:demo-bad scripts/scan-all.sh || true
    )
    rm -rf reports/demo-bad && mkdir -p reports && cp -r "${work}/repo/reports" reports/demo-bad
    cd "${work}/repo"
    status=0
    printf '\n\033[1;36m==> Vérification de la démo\033[0m\n'
    for gate in ${expected_blocked}; do
      if [ "$(result_of "${gate}")" = "failure" ]; then
        echo "  attendu BLOQUE, obtenu BLOQUE : ${gate}"
      else
        echo "  attendu BLOQUE, obtenu PASSE  : ${gate}   <-- le contrôle ne joue pas son rôle"; status=1
      fi
    done
    for gate in ${expected_passing}; do
      [ "$(result_of "${gate}")" = "success" ] || { echo "  attendu PASSE, obtenu BLOQUE : ${gate}"; status=1; }
    done
    if [ "${status}" -eq 0 ]; then
      printf '\n\033[32mDémo bad : chaque faille injectée est bloquée, la fusion serait refusée.\033[0m\n'
      echo "Journaux détaillés : reports/demo-bad/logs/"
    fi
    exit "${status}"
    ;;

  branch)
    git diff --quiet HEAD || { echo "Commite ou remise tes modifications avant de créer la branche de démo."; exit 1; }
    git switch --create demo/bad
    inject
    git add -A
    # --no-verify : on saute volontairement le hook local, c'est la couche 1 qu'on contourne.
    git commit --quiet --no-verify -m "demo: changements vulnérables (ne pas fusionner)"
    cat <<'MSG'

Branche demo/bad créée. Pour ouvrir la PR "bad" :
  git push -u origin demo/bad
  gh pr create --base main --head demo/bad --title "demo: PR vulnérable" --body "Doit être bloquée par le pipeline."
Pour revenir : git switch main
MSG
    ;;

  *)
    echo "usage : $0 good|bad|branch"; exit 2
    ;;
esac
