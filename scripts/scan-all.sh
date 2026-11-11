#!/usr/bin/env bash
# Lance tous les quality gates, sans s'arrêter au premier échec, puis affiche une synthèse.
# Code de sortie : 0 si tous les gates passent, 1 sinon.
set -uo pipefail

gates=(tests secrets sast sca image iac-trivy iac-checkov policy exceptions)
declare -A commands=(
  [tests]="test"
  [secrets]="secrets"
  [sast]="sast"
  [sca]="sca"
  [image]="build image-scan"
  [iac-trivy]="iac-trivy"
  [iac-checkov]="iac-checkov"
  [policy]="policy"
  [exceptions]="exceptions"
)

mkdir -p reports/logs
printf '{' > reports/gates.json
sep=""
failed=0
for gate in "${gates[@]}"; do
  printf '\n\033[1;36m==> %s\033[0m (make %s)\n' "${gate}" "${commands[$gate]}"
  # shellcheck disable=SC2086
  if make --no-print-directory ${commands[$gate]} 2>&1 | tee "reports/logs/${gate}.log"; then
    result=success
  else
    result=failure; failed=1
  fi
  printf '%s"%s": {"result": "%s"}' "${sep}" "${gate}" "${result}" >> reports/gates.json
  sep=", "
done
printf '}\n' >> reports/gates.json

printf '\n\033[1;36m==> Synthèse\033[0m\n'
for gate in "${gates[@]}"; do
  if grep -q "\"${gate}\": {\"result\": \"success\"}" reports/gates.json; then
    printf '  \033[32mPASSE \033[0m %s\n' "${gate}"
  else
    printf '  \033[31mBLOQUE\033[0m %s\n' "${gate}"
  fi
done
exit "${failed}"
