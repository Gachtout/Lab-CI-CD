#!/usr/bin/env bash
# Vérification de l'étape 2 : tests et image Docker.
source "$(dirname "$0")/lib.sh"
IMG="lab-check-e02:$$"

structure e02.dockerfile app/Dockerfile 1 2 3
structure e02.workflow .github/workflows/pr-security.yml 7
stage

d0=$(sandbox)
passes 5 "tests sur l'application fournie" "${d0}" test
d1=$(sandbox); inject_sqli "${d1}"
blocks 5 "tests sur une application dont un test doit échouer" "${d1}" test
stage

passes 6 "construction de l'image" "${d0}" build IMAGE="${IMG}"
if docker image inspect "${IMG}" >/dev/null 2>&1; then
  uid=$(docker run --rm --entrypoint id "${IMG}" -u 2>/dev/null || echo "?")
  if [ "${uid}" = "0" ] || [ "${uid}" = "?" ]; then ko 2 "le conteneur s'exécute avec l'identifiant ${uid} (app/Dockerfile)"; fi
  if [ -n "$(docker run --rm --user 0 --entrypoint sh "${IMG}" -c 'ls -A /root/.cache/pip 2>/dev/null | head -n 1')" ]; then
    ko 4 "l'image contient le cache de l'outil d'installation des dépendances (app/Dockerfile)"
  else
    ok 4
  fi
  docker rmi -f "${IMG}" >/dev/null 2>&1
else
  ko 6 "l'image nommée par la variable IMAGE n'existe pas après \`make build IMAGE=...\`"
fi
finish
