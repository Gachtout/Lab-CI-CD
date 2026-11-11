#!/usr/bin/env bash
# Vérifie que chaque exception de sécurité est justifiée ET datée, et qu'aucune n'a expiré.
#   - Checkov : commentaires "#checkov:skip=ID:raison - expire le AAAA-MM-JJ"
#   - Trivy   : entrées de .trivyignore.yaml (champs statement et expired_at)
# Trivy applique lui-même l'expiration ; ce script garantit en plus que la date existe.
set -euo pipefail

today=${TODAY:-$(date +%F)}
status=0

fail() { echo "ERREUR  $*"; status=1; }

echo "Exceptions Checkov (date du jour : ${today})"
while IFS= read -r line; do
  [ -n "${line}" ] || continue
  location=${line%%:#*}
  if [[ "${line}" =~ checkov:skip=([A-Z0-9_]+):(.+)\ -\ expire\ le\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    id=${BASH_REMATCH[1]}; expiry=${BASH_REMATCH[3]}
    if [[ "${expiry}" < "${today}" ]]; then
      fail "${location} : ${id} a expiré le ${expiry}"
    else
      echo "ok      ${id} jusqu'au ${expiry}  (${location})"
    fi
  else
    fail "${location} : exception sans justification ou sans date (format : ID:raison - expire le AAAA-MM-JJ)"
  fi
done < <(grep -rn --include='*.tf' --include='Dockerfile' 'checkov:skip=' terraform app 2>/dev/null | sed -E 's/^([^:]+:[0-9]+):[[:space:]]*/\1:/' || true)

echo "Exceptions Trivy"
if [ -f .trivyignore.yaml ]; then
  ids=$(grep -cE '^[[:space:]]*- id:' .trivyignore.yaml || true)
  dates=$(grep -cE '^[[:space:]]*expired_at:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' .trivyignore.yaml || true)
  reasons=$(grep -cE '^[[:space:]]*statement:' .trivyignore.yaml || true)
  if [ "${ids}" -ne "${dates}" ] || [ "${ids}" -ne "${reasons}" ]; then
    fail ".trivyignore.yaml : ${ids} exception(s), ${dates} date(s) expired_at, ${reasons} justification(s) statement"
  else
    echo "ok      ${ids} exception(s), toutes datées et justifiées"
  fi
  while IFS= read -r expiry; do
    [[ "${expiry}" < "${today}" ]] && fail ".trivyignore.yaml : une exception a expiré le ${expiry}"
  done < <(grep -oE 'expired_at:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' .trivyignore.yaml | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
fi

exit "${status}"
