#!/usr/bin/env bash
# Bibliothèque commune des vérifications d'étape.
# Règle : un message d'échec cite la contrainte et l'emplacement, jamais la correction.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT}"
ETAPE=${ETAPE:?ETAPE doit être défini}
FAILED=0
LOGDIR="${ROOT}/reports/checks"
mkdir -p "${LOGDIR}"
export CACHE="${CACHE:-${ROOT}/.cache}"
TMPBASE=$(mktemp -d)
# Sécurité : aucune vérification ne doit pouvoir agir sur un compte AWS réel.
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_PROFILE AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE
trap 'rm -rf -- "${TMPBASE}"' EXIT

ok() { printf '  ok     [C%s]\n' "$1"; }
ko() { printf '  ECHEC  [C%s] %s\n' "$1" "$2"; FAILED=1; }

# En mode rapide (banc de test), on s'arrête à la première série en échec.
stage() { if [ "${FAILED}" -ne 0 ] && [ -n "${CHECK_FAIL_FAST:-}" ]; then finish; fi; }

finish() {
  if [ "${FAILED}" -eq 0 ]; then
    echo "Étape ${ETAPE} : validée."
  else
    echo "Étape ${ETAPE} : non validée. Journaux détaillés : reports/checks/"
  fi
  exit "${FAILED}"
}

# loc <fichier> <ancre> : "fichier:ligne" de la première occurrence de l'ancre, sinon "fichier".
loc() {
  local line=""
  [ -n "${2:-}" ] && [ -f "$1" ] && line=$(grep -n -F -m1 -- "$2" "$1" | cut -d: -f1)
  if [ -n "${line}" ]; then echo "$1:${line}"; else echo "$1"; fi
}

need_file() { # need_file <contrainte> <fichier>
  if [ -e "$2" ]; then return 0; fi
  ko "$1" "fichier attendu absent : $2"
  return 1
}

conftest_run() { make -s --no-print-directory __conftest A="$*" 2>&1; }

# structure <espace-de-noms> <fichier> <contrainte>... : contrôles de structure écrits en Rego.
# Chaque violation sort sous la forme "[Cn] texte|ancre" ; l'ancre sert à retrouver la ligne.
structure() {
  local ns=$1 file=$2 out id found msg
  shift 2
  if [ ! -f "${file}" ]; then
    for id in "$@"; do ko "${id}" "fichier attendu absent : ${file}"; done
    return
  fi
  out=$(conftest_run "test ${file} --policy checks/policy --namespace ${ns} --no-color")
  if ! grep -qE '[0-9]+ tests?, ' <<<"${out}"; then
    printf '%s\n' "${out}" > "${LOGDIR}/etape-${ETAPE}-structure.log"
    for id in "$@"; do ko "${id}" "fichier illisible : ${file} (voir reports/checks/etape-${ETAPE}-structure.log)"; done
    return
  fi
  for id in "$@"; do
    found=$(grep -F "[C${id}] " <<<"${out}" || true)
    if [ -z "${found}" ]; then
      ok "${id}"
    else
      while IFS= read -r msg; do
        msg=${msg#*"[C${id}] "}
        ko "${id}" "${msg%%|*} ($(loc "${file}" "${msg#*|}"))"
      done <<<"${found}"
    fi
  done
}

# grep_has / grep_hasnt <contrainte> <message> <motif-regex> <fichier>...
grep_has() {
  local id=$1 msg=$2 pat=$3
  shift 3
  if grep -rqE -- "${pat}" "$@" 2>/dev/null; then ok "${id}"; else ko "${id}" "${msg}"; fi
}
grep_hasnt() {
  local id=$1 msg=$2 pat=$3 hit
  shift 3
  hit=$(grep -rnE -m1 -- "${pat}" "$@" 2>/dev/null | head -n 1 | cut -d: -f1,2)
  if [ -z "${hit}" ]; then ok "${id}"; else ko "${id}" "${msg} (${hit})"; fi
}

# sandbox : copie jetable du dépôt (sans cache ni rapports), initialisée comme dépôt git
# avec un premier commit : plusieurs outils exigent un dépôt, et l'historique sert à l'étape 3.
sandbox() {
  local d
  d=$(mktemp -d -p "${TMPBASE}")
  tar -C "${ROOT}" --exclude=./.cache --exclude=./reports --exclude=./.git --exclude=./site -cf - . | tar -C "${d}" -xf -
  git -C "${d}" init -q -b main
  git -C "${d}" add -A
  git -C "${d}" -c user.name=check -c user.email=check@lab.invalid commit -q --no-verify -m base
  echo "${d}"
}

mk() { # mk <dossier> <arguments make...>
  local d=$1
  shift
  make -s --no-print-directory -C "${d}" "$@"
}

# passes / blocks <contrainte> <description> <dossier> <arguments make...>
passes() {
  local id=$1 desc=$2 d=$3 log
  shift 3
  log="${LOGDIR}/etape-${ETAPE}-C${id}.log"
  if mk "${d}" "$@" >"${log}" 2>&1; then
    ok "${id}"
  else
    ko "${id}" "${desc} : \`make $*\` a échoué alors qu'il devait réussir (reports/checks/$(basename "${log}"))"
  fi
}
blocks() {
  local id=$1 desc=$2 d=$3 log
  shift 3
  log="${LOGDIR}/etape-${ETAPE}-C${id}.log"
  if mk "${d}" "$@" >"${log}" 2>&1; then
    ko "${id}" "${desc} : \`make $*\` a réussi alors qu'il devait échouer (reports/checks/$(basename "${log}"))"
  else
    ok "${id}"
  fi
}

# stub_guard <contrainte> <cible> : échoue si la cible est encore le gabarit du squelette.
is_stub() { grep -qE "^$1:.*\[À FAIRE\]" Makefile; }

# --- Fautes injectées dans une copie jetable ---------------------------------
# Les jetons factices sont assemblés ici pour ne figurer en clair dans aucun fichier.
fake_lab_token() { printf 'LABFAKE_%s' 7Q2M9X4K1Z8W3R6T5Y0B2N4C; }
fake_std_token() { printf 'ghp_%s' R8mK2pX7vQ4nL9sT3wY6zB1cD5fG0hJaE2uN; }

commit_all() { git -C "$1" add -A && git -C "$1" -c user.name=check -c user.email=check@lab.invalid commit -q --no-verify -m "$2"; }

inject_sqli() { sed -i "s|WHERE name = ?\", (name,))|WHERE name = '%s'\" % name)|" "$1/app/app.py"; }
inject_secret_dur() { sed -i 's|^\(    \)app.config\["API_TOKEN"\] = .*|&\n\1app.config["API_TOKEN"] = "jeton-en-dur-a-remplacer"|' "$1/app/app.py"; }
inject_debug() { sed -i 's|^\(    \)app.config\["API_TOKEN"\] = .*|&\n\1app.config["DEBUG"] = True|' "$1/app/app.py"; }
inject_md5() { printf '\nimport hashlib\n\n\ndef empreinte(valeur):\n    return hashlib.md5(valeur.encode()).hexdigest()\n' >> "$1/app/app.py"; }
inject_deps_vuln() { printf 'flask==2.2.2\nwerkzeug==2.2.2\ngunicorn==27.0.0\n' > "$1/app/requirements.txt"; }

need_report() { # need_report <contrainte> <dossier> <chemin relatif>
  if [ -s "$2/$3" ]; then ok "$1"; else ko "$1" "rapport attendu absent ou vide : $3"; fi
}

# fixture_accepted <fichier de plan> : vrai si tes policies acceptent ce plan.
fixture_accepted() { conftest_run "test checks/fixtures/$1 --policy policies --all-namespaces --no-color" > "${LOGDIR}/etape-${ETAPE}-$1.log"; }
