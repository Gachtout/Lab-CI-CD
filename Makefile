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
	$(RUN) $(ACTIONLINT_IMAGE) 2>&1 | tee $(REPORTS)/actionlint.txt
