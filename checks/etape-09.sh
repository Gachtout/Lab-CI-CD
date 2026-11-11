#!/usr/bin/env bash
# Vérification de l'étape 9 : protection de branche. STATIQUE UNIQUEMENT :
# aucun appel à GitHub, le script de configuration n'est jamais exécuté.
source "$(dirname "$0")/lib.sh"
RS=.github/rulesets/main.json
SC=scripts/setup-github.sh

structure e09.ruleset "${RS}" 1 2 3 4 5

if need_file 6 "${SC}"; then
  if bash -n "${SC}" 2>/dev/null; then ok 6; else ko 6 "le script contient une erreur de syntaxe (${SC})"; fi
  if [ -x "${SC}" ]; then ok 6; else ko 6 "le script n'est pas exécutable (${SC})"; fi
  grep_has 6 "le script n'applique pas le fichier de ruleset versionné (${SC})" '\.github/rulesets/main\.json' "${SC}"
  grep_has 6 "le script n'active pas la protection contre le push de secrets (${SC})" 'secret_scanning_push_protection' "${SC}"
  grep_has 7 "relancé, le script créerait un second ruleset au lieu de mettre à jour l'existant (${SC})" '(PUT|PATCH)[^\n]*rulesets/' "${SC}"
fi
finish
