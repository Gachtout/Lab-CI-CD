#!/usr/bin/env bash
# Couche 3 du blocage : applique la configuration GitHub du dépôt, de façon rejouable.
#   1. secret scanning + push protection
#   2. ruleset "main-protegee" (.github/rulesets/main.json)
#   3. environnements "dev-plan" et "dev" (approbation manuelle), limités à la branche main
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

echo "3/3 Environnements dev-plan (lecture seule) et dev (approbation manuelle)"
user_id=$(gh api user --jq .id)
# Les deux environnements ne se déploient que depuis main : une branche de PR ne peut pas obtenir d'identifiants AWS.
gh api --method PUT "repos/${repo}/environments/dev-plan" --silent --input - <<JSON
{
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true }
}
JSON
gh api --method PUT "repos/${repo}/environments/dev" --silent --input - <<JSON
{
  "reviewers": [{ "type": "User", "id": ${user_id} }],
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true }
}
JSON
for env in dev-plan dev; do
  gh api --method POST "repos/${repo}/environments/${env}/deployment-branch-policies" --silent \
    -f name=main -f type=branch 2>/dev/null || echo "    ${env} : règle de branche main déjà présente"
done

echo "Terminé. Vérifie : https://github.com/${repo}/settings/rules"
