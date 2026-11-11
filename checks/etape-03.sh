#!/usr/bin/env bash
# Vérification de l'étape 3 : détection de secrets.
source "$(dirname "$0")/lib.sh"

structure e03.gitleaks .gitleaks.toml 2
structure e03.precommit .pre-commit-config.yaml 6
structure e03.workflow .github/workflows/pr-security.yml 7
stage

d0=$(sandbox)
passes 1 "historique sans secret" "${d0}" secrets
need_report 4 "${d0}" reports/gitleaks.sarif
stage

d1=$(sandbox); printf 'TOKEN = "%s"\n' "$(fake_std_token)" > "${d1}/app/conf_a.py"; commit_all "${d1}" "ajout"
blocks 1 "secret au format d'un fournisseur connu, commité" "${d1}" secrets
stage

d2=$(sandbox); printf 'TOKEN = "%s"\n' "$(fake_lab_token)" > "${d2}/app/conf_b.py"; commit_all "${d2}" "ajout"
blocks 2 "jeton au format maison, commité" "${d2}" secrets
if grep -qF "$(fake_lab_token)" "${LOGDIR}/etape-03-C2.log" 2>/dev/null; then
  ko 8 "la valeur du secret apparaît en clair dans la sortie de \`make secrets\`"
else
  ok 8
fi
stage

d3=$(sandbox); printf 'TOKEN = "%s"\n' "$(fake_lab_token)" > "${d3}/app/conf_c.py"; commit_all "${d3}" "ajout"
git -C "${d3}" rm -q app/conf_c.py; commit_all "${d3}" "retrait"
blocks 3 "secret commité puis supprimé dans un commit suivant" "${d3}" secrets
stage

passes 5 "aucun fichier indexé" "${d0}" secrets-staged
d4=$(sandbox); printf 'TOKEN = "%s"\n' "$(fake_lab_token)" > "${d4}/app/conf_d.py"; git -C "${d4}" add -A
blocks 5 "secret indexé mais pas encore commité" "${d4}" secrets-staged
finish
