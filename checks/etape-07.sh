#!/usr/bin/env bash
# Vérification de l'étape 7 : scan IaC et policies maison.
source "$(dirname "$0")/lib.sh"
ENV_DIR=terraform/envs/dev

structure e07.workflow .github/workflows/pr-security.yml 10
structure e07.planworkflow .github/workflows/terraform-plan.yml 10
stage

# Tes policies face à des plans de référence (checks/fixtures/).
if fixture_accepted plan-sain.json; then ok 3; else ko 3 "tes policies refusent un plan conforme (checks/fixtures/plan-sain.json)"; fi
stage
if fixture_accepted plan-bucket-public.json; then ko 4 "tes policies acceptent un bucket exposable publiquement (checks/fixtures/plan-bucket-public.json)"; else ok 4; fi
stage
if fixture_accepted plan-entree-ouverte.json; then ko 5 "tes policies acceptent une entrée ouverte à tout Internet (checks/fixtures/plan-entree-ouverte.json)"; else ok 5; fi
stage
if fixture_accepted plan-tag-manquant.json; then ko 6 "tes policies acceptent une ressource sans tag obligatoire (checks/fixtures/plan-tag-manquant.json)"; else ok 6; fi
stage
if fixture_accepted plan-ressource-payante.json; then ko 7 "tes policies acceptent une ressource payante (checks/fixtures/plan-ressource-payante.json)"; else ok 7; fi
stage

d0=$(sandbox)
log="${LOGDIR}/etape-07-C8.log"
if mk "${d0}" policy-test >"${log}" 2>&1; then
  n=$(grep -oE '[0-9]+ tests?, [0-9]+ passed' "${log}" | tail -n 1 | grep -oE '^[0-9]+' || echo 0)
  if [ "${n:-0}" -ge 4 ]; then ok 8; else ko 8 "${n:-0} test(s) unitaire(s) de policies trouvé(s) par \`make policy-test\`"; fi
else
  ko 8 "\`make policy-test\` a échoué (reports/checks/etape-07-C8.log)"
fi
stage

passes 3 "policies appliquées à ton plan" "${d0}" policy
stage
d1=$(sandbox); cp checks/faults/etape-07/bucket-public.faute "${d1}/${ENV_DIR}/zz_check.tf"
blocks 9 "policies appliquées à un plan contenant un bucket exposable" "${d1}" policy
stage
passes 1 "scan IaC de ton code (Trivy)" "${d0}" iac-trivy
blocks 1 "scan IaC d'un bucket exposable (Trivy)" "${d1}" iac-trivy
stage
passes 2 "scan IaC de ton code (Checkov)" "${d0}" iac-checkov
blocks 2 "scan IaC d'un bucket exposable (Checkov)" "${d1}" iac-checkov
finish
