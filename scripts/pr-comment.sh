#!/usr/bin/env bash
# Publie ou met à jour UN commentaire de PR identifié par un marqueur.
# Usage : pr-comment.sh <marqueur> <fichier-markdown>
# Attend GH_TOKEN, GITHUB_REPOSITORY et PR_NUMBER dans l'environnement.
set -euo pipefail

marker="<!-- devsecops-lab:$1 -->"
body="${marker}"$'\n'"$(cat "$2")"

existing=$(gh api "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"${marker}\")) | .id" | head -n 1)

if [ -n "${existing}" ]; then
  gh api --method PATCH "repos/${GITHUB_REPOSITORY}/issues/comments/${existing}" -f body="${body}" >/dev/null
  echo "Commentaire ${existing} mis à jour."
else
  gh api --method POST "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" -f body="${body}" >/dev/null
  echo "Commentaire créé."
fi
