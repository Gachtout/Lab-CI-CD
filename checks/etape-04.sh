#!/usr/bin/env bash
# Vérification de l'étape 4 : SAST et SCA.
source "$(dirname "$0")/lib.sh"

structure e04.workflow .github/workflows/pr-security.yml 8
stage

d0=$(sandbox)
passes 1 "code sain" "${d0}" sast
need_report 7 "${d0}" reports/semgrep.sarif
stage
d1=$(sandbox); inject_sqli "${d1}"
blocks 1 "injection SQL" "${d1}" sast
stage
d2=$(sandbox); inject_secret_dur "${d2}"
blocks 2 "secret de configuration en dur" "${d2}" sast
stage
d3=$(sandbox); inject_debug "${d3}"
blocks 3 "mode debug activé en dur" "${d3}" sast
stage
d4=$(sandbox); inject_md5 "${d4}"
passes 4 "constat de sévérité inférieure au seuil" "${d4}" sast
stage

passes 5 "dépendances saines" "${d0}" sca
need_report 7 "${d0}" reports/trivy-sca.sarif
d5=$(sandbox); inject_deps_vuln "${d5}"
blocks 5 "dépendances vulnérables avec correctif" "${d5}" sca
stage
passes 6 "mêmes dépendances, seuil relevé par la variable TRIVY_SEVERITY" "${d5}" sca TRIVY_SEVERITY=CRITICAL
finish
