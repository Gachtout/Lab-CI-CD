#!/usr/bin/env bash
# Vérification de l'étape 6 : Terraform, format, validation et plan hors ligne.
source "$(dirname "$0")/lib.sh"
ENV_DIR=terraform/envs/dev

structure e06.workflow .github/workflows/terraform-plan.yml 8
need_file 6 "${ENV_DIR}/.terraform.lock.hcl"
if [ -d "${ENV_DIR}" ]; then
  grep_has 7 "aucun backend S3 n'est déclaré dans ${ENV_DIR}" 'backend "s3"' "${ENV_DIR}"
  grep_has 7 "l'état distant n'est pas chiffré (${ENV_DIR})" 'encrypt[[:space:]]*=[[:space:]]*true' "${ENV_DIR}"
  grep_has 7 "le verrou d'état natif n'est pas activé (${ENV_DIR})" 'use_lockfile[[:space:]]*=[[:space:]]*true' "${ENV_DIR}"
else
  ko 7 "dossier attendu absent : ${ENV_DIR}"
fi
stage

d0=$(sandbox)
passes 1 "format de ton code" "${d0}" tf-fmt
d1=$(sandbox); cp checks/faults/etape-06/mal-formate.faute "${d1}/${ENV_DIR}/zz_check.tf"
blocks 1 "fichier mal formaté" "${d1}" tf-fmt
stage
passes 2 "validation de ton code" "${d0}" tf-validate
d2=$(sandbox); cp checks/faults/etape-06/invalide.faute "${d2}/${ENV_DIR}/zz_check.tf"
blocks 2 "référence invalide" "${d2}" tf-validate
stage
passes 3 "plan sans aucun identifiant AWS" "${d0}" plan
need_report 3 "${d0}" reports/tfplan.json
stage
cp "${d0}/reports/tfplan.json" "${LOGDIR}/tfplan-etape-06.json"
structure e06.plan reports/checks/tfplan-etape-06.json 4 5
finish
