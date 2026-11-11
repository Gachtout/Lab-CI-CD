#!/usr/bin/env bash
# Couche 3 du blocage : applique la configuration GitHub du dépôt, de façon rejouable.
#   1. secret scanning + push protection
#   2. ruleset "main-protegee" (.github/rulesets/main.json)
#   3. environnement "dev" avec approbation manuelle (utilisé par deploy.yml et destroy.yml)
# Prérequis : gh CLI authentifié avec les droits d'administration du dépôt.
# Usage : scripts/setup-github.sh [owner/repo]
set -euo pipefail

repo=${1:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}
echo "Dépôt : ${repo}"

echo "1/3 Secret scanning et push protection"
gh api --method PATCH "repos/${repo}" --silent \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'

echo "2/3 Ruleset main-protegee"
existing=$(gh api "repos/${repo}/rulesets" --jq '.[] | select(.name == "main-protegee") | .id' | head -n 1)
if [ -n "${existing}" ]; then
  gh api --method PUT "repos/${repo}/rulesets/${existing}" --input .github/rulesets/main.json --silent
  echo "    ruleset ${existing} mis à jour"
else
  gh api --method POST "repos/${repo}/rulesets" --input .github/rulesets/main.json --silent
  echo "    ruleset créé"
fi

echo "3/3 Environnement dev avec approbation manuelle"
user_id=$(gh api user --jq .id)
gh api --method PUT "repos/${repo}/environments/dev" --silent --input - <<JSON
{
  "reviewers": [{ "type": "User", "id": ${user_id} }],
  "deployment_branch_policy": { "protected_branches": true, "custom_branch_policies": false }
}
JSON

echo "Terminé. Vérifie : https://github.com/${repo}/settings/rules"
