#!/usr/bin/env bash
# Vérification de l'étape 8 : quality gates, exceptions et verdict.
source "$(dirname "$0")/lib.sh"

structure e08.workflow .github/workflows/pr-security.yml 1 4 5 8 9

# Seuils par défaut, lus dans la commande que make exécuterait (aucun outil n'est lancé).
if is_stub sca || is_stub sast; then
  ko 3 "les cibles sca et sast doivent exister pour lire leurs seuils (Makefile)"
else
  sca_cmd=$(make -n sca V=1 2>/dev/null || true); sast_cmd=$(make -n sast V=1 2>/dev/null || true)
  if grep -q -- '--severity HIGH,CRITICAL' <<<"${sca_cmd}" && grep -q -- '--ignore-unfixed' <<<"${sca_cmd}"; then ok 3
  else ko 3 "seuil par défaut des vulnérabilités différent de celui de l'énoncé ($(loc Makefile 'TRIVY_SEVERITY'))"; fi
  if grep -q -- '--severity ERROR' <<<"${sast_cmd}"; then ok 3
  else ko 3 "seuil par défaut du SAST différent de celui de l'énoncé ($(loc Makefile 'SEMGREP_SEVERITY'))"; fi
fi
stage

d0=$(sandbox)
passes 1 "exceptions de ton dépôt" "${d0}" exceptions
stage
d1=$(sandbox); printf '#checkov:skip=CKV_AWS_999:exception de test sans date\n' > "${d1}/terraform/envs/dev/zz_check.tf"
blocks 2 "exception sans date d'expiration" "${d1}" exceptions
d2=$(sandbox); printf '#checkov:skip=CKV_AWS_999:exception de test - expire le 2020-01-01\n' > "${d2}/terraform/envs/dev/zz_check.tf"
blocks 2 "exception expirée" "${d2}" exceptions
stage

NEEDS_JSON='{"a":{"result":"success"},"b":{"result":"success"}}' passes 6 "tous les contrôles en succès" "${d0}" summary
NEEDS_JSON='{"a":{"result":"success"},"b":{"result":"skipped"}}' blocks 6 "un contrôle sauté" "${d0}" summary
stage

d3=$(sandbox)
passes 7 "tous les contrôles sur ton dépôt" "${d3}" scan
stage
d4=$(sandbox); printf 'TOKEN = "%s"\n' "$(fake_lab_token)" > "${d4}/app/conf_e.py"; commit_all "${d4}" "ajout"
blocks 7 "tous les contrôles sur un dépôt contenant un secret" "${d4}" scan
if ! grep -q '"exceptions"' "${d4}/reports/gates.json" 2>/dev/null; then
  ko 7 "\`make scan\` s'est arrêté au premier contrôle en échec (reports/gates.json incomplet)"
fi
finish
