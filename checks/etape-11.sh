#!/usr/bin/env bash
# Vérification de l'étape 11 : SBOM et Prowler. La cible prowler n'est jamais exécutée.
source "$(dirname "$0")/lib.sh"
OK_IMG="lab-check-sbom:$$"; VULN_IMG="lab-check-sbom-vuln:$$"
cleanup_images() { docker rmi -f "${OK_IMG}" "${VULN_IMG}" >/dev/null 2>&1; rm -rf -- "${TMPBASE}"; }
trap cleanup_images EXIT

structure e11.workflow .github/workflows/pr-security.yml 4
if is_stub prowler; then
  ko 3 "cible prowler non implémentée ($(loc Makefile 'prowler:'))"
elif make -n prowler AWS_REGION=eu-west-3 V=1 2>/dev/null | grep -i 'prowler' | grep -q '@sha256:[0-9a-f]\{64\}'; then
  ok 3
else
  ko 3 "l'image Prowler n'est pas épinglée par digest ($(loc Makefile 'PROWLER_IMAGE'))"
fi
stage

d0=$(sandbox)
passes 1 "inventaire de ton image" "${d0}" build sbom IMAGE="${OK_IMG}"
if grep -q '"bomFormat": *"CycloneDX"' "${d0}/reports/sbom.cdx.json" 2>/dev/null && grep -q '"components"' "${d0}/reports/sbom.cdx.json"; then
  ok 1
else
  ko 1 "reports/sbom.cdx.json absent, ou pas au format demandé"
fi
stage
passes 2 "recherche de vulnérabilités à partir de l'inventaire seul" "${d0}" sbom-scan
stage
d1=$(sandbox); cp checks/faults/etape-05/image-vulnerable.faute "${d1}/app/Dockerfile"; cp checks/faults/etape-05/dependances.faute "${d1}/app/requirements.txt"
if mk "${d1}" build sbom IMAGE="${VULN_IMG}" >"${LOGDIR}/etape-11-build-vuln.log" 2>&1; then
  blocks 2 "inventaire d'une image vulnérable" "${d1}" sbom-scan
else
  ko 2 "l'inventaire de l'image de test n'a pas pu être produit (reports/checks/etape-11-build-vuln.log)"
fi
finish
