# Lab DevSecOps : toutes les commandes tournent dans des images Docker épinglées par digest.
# La CI appelle exactement ces cibles : ce qui est vert ici est vert dans GitHub Actions.
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Images d'outils (tag lisible + digest immuable). Justification : docs/adr/0002.
# ----------------------------------------------------------------------------
DOCKERHUB        ?= docker.io
ACTIONLINT_IMAGE := $(DOCKERHUB)/rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667
PYTHON_IMAGE     := public.ecr.aws/docker/library/python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
GITLEAKS_IMAGE   := ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f
SEMGREP_IMAGE    := $(DOCKERHUB)/semgrep/semgrep:1.185.0@sha256:67518c174185a2043fdbed16c70631b79209499b3671178e7194379b48295a0d
TRIVY_IMAGE      := ghcr.io/aquasecurity/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb
CHECKOV_IMAGE    := ghcr.io/bridgecrewio/checkov:3.4.3@sha256:bfe9d70bb7f044aba49bd99675813445f106dee6072da583f51008cb667f3a63
TERRAFORM_IMAGE  := $(DOCKERHUB)/hashicorp/terraform:1.17.1@sha256:a5d5a5a892c98f60fcbfa81eac2a40fc19e7b3fa7719bccae10ff6111d22524a
CONFTEST_IMAGE   := $(DOCKERHUB)/openpolicyagent/conftest:v0.71.1@sha256:0e77cdf7c1fcde035f3c579e4aaa6664ee2a8be5777eaa9af9f520cdd02280c0

# ----------------------------------------------------------------------------
# Quality gates : les seuils qui font échouer une cible (détail : étape 8).
# ----------------------------------------------------------------------------
TRIVY_SEVERITY   ?= HIGH,CRITICAL
SEMGREP_SEVERITY ?= ERROR

# ----------------------------------------------------------------------------
# Réseau d'entreprise (facultatif) : proxy sortant et autorité de certification.
#   make scan DOCKER_NET=host CA_BUNDLE=/chemin/vers/bundle-complet.pem
# ----------------------------------------------------------------------------
DOCKER_NET  ?=
CA_BUNDLE   ?=
DOCKER_USER ?= $(shell id -u):$(shell id -g)

CA_FLAGS := $(if $(CA_BUNDLE),-v "$(CA_BUNDLE)":/etc/ssl/lab-ca.pem:ro \
  -e SSL_CERT_FILE=/etc/ssl/lab-ca.pem -e REQUESTS_CA_BUNDLE=/etc/ssl/lab-ca.pem -e PIP_CERT=/etc/ssl/lab-ca.pem)
NET_FLAGS := $(if $(DOCKER_NET),--network $(DOCKER_NET))
RUN := docker run --rm $(NET_FLAGS) --user $(DOCKER_USER) -e HOME=/tmp \
  -e HTTPS_PROXY -e https_proxy -e NO_PROXY -e no_proxy $(CA_FLAGS) \
  -v "$(CURDIR)":/src -w /src

REPORTS := reports

# make V=1 affiche les commandes docker complètes
Q := $(if $(V),,@)

.PHONY: help
help: ## Affiche les cibles disponibles
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

$(REPORTS):
	@mkdir -p $(REPORTS)

.PHONY: clean
clean: ## Supprime les rapports et les caches locaux
	rm -rf $(REPORTS) .cache

# ----------------------------------------------------------------------------
# Étape 1 : pipeline minimal
# ----------------------------------------------------------------------------
.PHONY: lint-workflows
lint-workflows: | $(REPORTS) ## Vérifie la syntaxe des workflows GitHub Actions (actionlint)
	$(Q)$(RUN) $(ACTIONLINT_IMAGE) 2>&1 | tee $(REPORTS)/actionlint.txt

# ----------------------------------------------------------------------------
# Étape 2 : tests et image Docker
# ----------------------------------------------------------------------------
IMAGE          ?= devsecops-lab-app:local
DOCKER_BUILD   ?= docker build $(NET_FLAGS)

.PHONY: test
test: ## Lance les tests unitaires de l'application (pytest)
	$(Q)$(RUN) -w /src/app -e PYTHONDONTWRITEBYTECODE=1 $(PYTHON_IMAGE) sh -c '\
	  python -m venv /tmp/venv && \
	  /tmp/venv/bin/pip install --quiet --disable-pip-version-check -r requirements.txt -r requirements-dev.txt && \
	  /tmp/venv/bin/python -m pytest -q -p no:cacheprovider tests'

.PHONY: build
build: ## Construit l'image Docker de l'application
	$(Q)$(DOCKER_BUILD) -t $(IMAGE) app

# ----------------------------------------------------------------------------
# Étape 3 : secrets
# ----------------------------------------------------------------------------
# safe.directory : le dépôt monté n'appartient pas forcément à l'utilisateur du conteneur.
GITLEAKS := $(RUN) -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0=/src \
  $(GITLEAKS_IMAGE) --config .gitleaks.toml --redact --no-banner --verbose

.PHONY: secrets
secrets: | $(REPORTS) ## Cherche des secrets dans tout l'historique git (Gitleaks) : bloque toujours
	$(Q)$(GITLEAKS) git --report-format sarif --report-path $(REPORTS)/gitleaks.sarif .

.PHONY: secrets-staged
secrets-staged: ## Cherche des secrets dans les fichiers indexés (utilisé par le hook pre-commit)
	$(Q)$(GITLEAKS) git --pre-commit --staged .

# ----------------------------------------------------------------------------
# Étape 4 : SAST (ton code) et SCA (tes dépendances)
# ----------------------------------------------------------------------------
SEMGREP := $(RUN) -e SEMGREP_SEND_METRICS=off -e SEMGREP_ENABLE_VERSION_CHECK=0 $(SEMGREP_IMAGE) semgrep scan \
  --config p/python --config p/flask --config .semgrep/ --quiet
TRIVY := $(RUN) -e TRIVY_CACHE_DIR=/src/.cache/trivy -e TRIVY_NO_PROGRESS=true $(TRIVY_IMAGE)
TRIVY_GATE := --severity $(TRIVY_SEVERITY) --ignore-unfixed --exit-code 1

.PHONY: sast
sast: | $(REPORTS) ## Analyse statique du code (Semgrep) : bloque sur la sévérité ERROR
	$(Q)$(SEMGREP) --sarif-output $(REPORTS)/semgrep.sarif --text --error --severity $(SEMGREP_SEVERITY) app

.PHONY: sca
sca: | $(REPORTS) ## Dépendances vulnérables (Trivy fs) : bloque sur HIGH/CRITICAL avec correctif
	$(Q)$(TRIVY) fs --scanners vuln --format sarif --output $(REPORTS)/trivy-sca.sarif app
	$(Q)$(TRIVY) fs --scanners vuln $(TRIVY_GATE) app

# ----------------------------------------------------------------------------
# Étape 5 : image Docker
# ----------------------------------------------------------------------------
IMAGE_TAR := .cache/image.tar

# L'image est exportée en archive : Trivy n'a pas besoin d'accéder au socket Docker.
$(IMAGE_TAR): FORCE
	$(Q)mkdir -p .cache && docker save $(IMAGE) -o $(IMAGE_TAR)
FORCE:

.PHONY: image-scan
image-scan: $(IMAGE_TAR) | $(REPORTS) ## Scanne l'image (paquets OS, dépendances, secrets, configuration)
	$(Q)$(TRIVY) image --input $(IMAGE_TAR) --scanners vuln,secret --image-config-scanners misconfig,secret \
	  --format sarif --output $(REPORTS)/trivy-image.sarif
	$(Q)$(TRIVY) image --input $(IMAGE_TAR) --scanners vuln,secret --image-config-scanners misconfig,secret \
	  $(TRIVY_GATE)

# ----------------------------------------------------------------------------
# Étape 6 : Terraform (fmt, validate, plan sans compte AWS)
# ----------------------------------------------------------------------------
TF_ENV := terraform/envs/dev
# Les providers sont mis en cache hors de l'arbre git ; TF_DATA_DIR évite tout .terraform/ dans le dépôt.
TERRAFORM := $(RUN) -e TF_IN_AUTOMATION=1 -e TF_PLUGIN_CACHE_DIR=/src/.cache/terraform/plugins \
  -e TF_DATA_DIR=/src/.cache/terraform/data -e CHECKPOINT_DISABLE=1

.cache/terraform/plugins:
	@mkdir -p $@

.PHONY: tf-fmt
tf-fmt: | .cache/terraform/plugins ## Vérifie le formatage Terraform (terraform fmt -check)
	$(Q)$(TERRAFORM) $(TERRAFORM_IMAGE) fmt -check -recursive -diff terraform

.PHONY: tf-validate
tf-validate: | .cache/terraform/plugins ## Valide la syntaxe et la cohérence du code Terraform
	$(Q)$(TERRAFORM) --entrypoint sh $(TERRAFORM_IMAGE) -c '\
	  cd $(TF_ENV) && terraform init -backend=false -input=false >/dev/null && terraform validate'

# Plan hors ligne : backend local jetable et faux identifiants, dans une copie temporaire.
# Rien n'est créé, aucun appel AWS n'est émis ; le plan est exporté en JSON pour les policies.
.PHONY: plan
plan: | $(REPORTS) .cache/terraform/plugins ## terraform plan sans compte AWS, exporté dans reports/tfplan.json
	$(Q)$(TERRAFORM) -e TF_VAR_offline=true -e AWS_ACCESS_KEY_ID=offline -e AWS_SECRET_ACCESS_KEY=offline \
	  -e TF_DATA_DIR=/tmp/tfdata --entrypoint sh $(TERRAFORM_IMAGE) -c '\
	  cp -r terraform /tmp/tf && cd /tmp/tf/envs/dev && \
	  printf "terraform {\n  backend \"local\" {}\n}\n" > backend_override.tf && \
	  terraform init -input=false >/dev/null && \
	  terraform plan -input=false -lock=false -out=/tmp/tfplan && \
	  terraform show -json /tmp/tfplan > /src/$(REPORTS)/tfplan.json && \
	  terraform show -no-color /tmp/tfplan > /src/$(REPORTS)/tfplan.txt'

.PHONY: tf-lock
tf-lock: | .cache/terraform/plugins ## Régénère .terraform.lock.hcl (à lancer après un changement de version de provider)
	$(Q)$(TERRAFORM) --entrypoint sh $(TERRAFORM_IMAGE) -c '\
	  cd $(TF_ENV) && terraform init -backend=false -input=false >/dev/null && \
	  terraform providers lock -platform=linux_amd64 -platform=linux_arm64'
