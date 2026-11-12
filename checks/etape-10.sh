#!/usr/bin/env bash
# Vérification de l'étape 10 : OIDC, apply, destroy. STATIQUE UNIQUEMENT :
# le bootstrap est planifié hors ligne avec de faux identifiants, aucune cible aws-* n'est exécutée.
source "$(dirname "$0")/lib.sh"
BOOT=terraform/bootstrap
WFS=.github/workflows

structure e10.deploy "${WFS}/deploy.yml" 6 7 8
structure e10.destroy "${WFS}/destroy.yml" 6 7
grep_hasnt 6 "un workflow référence une clé d'accès AWS statique" '(AWS_SECRET_ACCESS_KEY|aws-secret-access-key|aws-access-key-id|AWS_ACCESS_KEY_ID)' "${WFS}"

if [ -n "$(ls "${BOOT}"/*.tf 2>/dev/null)" ]; then
  grep_has 2 "aucune condition ne porte sur le champ sub du jeton (${BOOT})" 'githubusercontent\.com:sub' "${BOOT}"
  grep_hasnt 2 "une condition de confiance compare par motif au lieu d'une égalité stricte" 'StringLike' "${BOOT}"
  grep_hasnt 2 "le sujet accepté contient un joker" 'repo:[^"]*\*' "${BOOT}"
  grep_has 2 "le sujet accepté n'est pas lié à un environnement GitHub (${BOOT})" 'repo:[^"]*:environment:' "${BOOT}"
  grep_has 3 "aucune condition ne porte sur l'audience du jeton (${BOOT})" 'githubusercontent\.com:aud' "${BOOT}"
  grep_hasnt 9 "une politique accorde toutes les actions" '(actions[[:space:]]*=[[:space:]]*\["\*"\]|AdministratorAccess|"\*:\*")' "${BOOT}"
else
  for c in 2 3 9; do ko "${c}" "aucun fichier Terraform dans ${BOOT}"; done
fi

for target in aws-apply aws-destroy; do
  if is_stub "${target}"; then
    ko 10 "cible ${target} non implémentée ($(loc Makefile "${target}:"))"
  elif make -n "${target}" AWS_REGION=eu-west-3 TF_STATE_BUCKET=exemple 2>/dev/null | grep -q 'AWS_CONFIRM'; then
    ok 10
  else
    ko 10 "la cible ${target} s'exécute sans confirmation explicite ($(loc Makefile "${target}:"))"
  fi
done
stage

d0=$(sandbox); mkdir -p "${d0}/reports/checks"
plan_cmd='cp -r terraform /tmp/tf && cd /tmp/tf/bootstrap && terraform init -input=false >/dev/null && terraform plan -input=false -out=/tmp/p -var offline=true -var github_repository=exemple/depot -var budget_email=test@example.org >/dev/null && terraform show -json /tmp/p > /src/reports/checks/bootstrap-plan.json'
tf_opts='-e TF_IN_AUTOMATION=1 -e CHECKPOINT_DISABLE=1 -e TF_PLUGIN_CACHE_DIR=/cache/terraform/plugins -e TF_DATA_DIR=/tmp/tfdata -e AWS_ACCESS_KEY_ID=offline -e AWS_SECRET_ACCESS_KEY=offline --entrypoint sh'
if mk "${d0}" __tool IMG=TERRAFORM_IMAGE O="${tf_opts}" A="-c '${plan_cmd}'" >"${LOGDIR}/etape-10-plan.log" 2>&1 && [ -s "${d0}/reports/checks/bootstrap-plan.json" ]; then
  cp "${d0}/reports/checks/bootstrap-plan.json" "${LOGDIR}/bootstrap-plan.json"
  structure e10.plan reports/checks/bootstrap-plan.json 1 3 4 5
else
  ko 1 "le bootstrap ne se planifie pas hors ligne avec les variables imposées (reports/checks/etape-10-plan.log)"
fi
finish
