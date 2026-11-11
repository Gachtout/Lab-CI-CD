#!/usr/bin/env bash
# Vérification de l'étape 5 : scan de l'image Docker.
source "$(dirname "$0")/lib.sh"
OK_IMG="lab-check-ok:$$"; ROOT_IMG="lab-check-root:$$"; VULN_IMG="lab-check-vuln:$$"
cleanup_images() { docker rmi -f "${OK_IMG}" "${ROOT_IMG}" "${VULN_IMG}" >/dev/null 2>&1; rm -rf -- "${TMPBASE}"; }
trap cleanup_images EXIT

structure e05.workflow .github/workflows/pr-security.yml 6
grep_hasnt 3 "le scan d'image a accès au socket Docker" 'docker\.sock' Makefile
stage

d0=$(sandbox)
passes 1 "image de l'application" "${d0}" build image-scan IMAGE="${OK_IMG}"
need_report 5 "${d0}" reports/trivy-image.sarif
stage

d1=$(sandbox); cp checks/faults/etape-05/image-vulnerable.faute "${d1}/app/Dockerfile"; cp checks/faults/etape-05/dependances.faute "${d1}/app/requirements.txt"
if mk "${d1}" build IMAGE="${VULN_IMG}" >"${LOGDIR}/etape-05-build-vuln.log" 2>&1; then
  blocks 2 "image de base en fin de vie" "${d1}" image-scan IMAGE="${VULN_IMG}"
else
  ko 2 "l'image de test n'a pas pu être construite avec \`make build\` (reports/checks/etape-05-build-vuln.log)"
fi
stage

if printf 'FROM %s\nUSER root\n' "${OK_IMG}" | docker build -q -t "${ROOT_IMG}" - >/dev/null 2>&1; then
  blocks 4 "même image, exécutée en root" "${d0}" image-scan IMAGE="${ROOT_IMG}"
else
  ko 4 "l'image de test en root n'a pas pu être dérivée de la tienne"
fi
finish
