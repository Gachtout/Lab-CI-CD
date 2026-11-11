# Lab DevSecOps, mode exercice. La plomberie Docker ci-dessous est fournie ;
# les cibles marquées [À FAIRE] sont à écrire, étape par étape (docs/etapes/).
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
# Réseau d'entreprise (facultatif) : proxy sortant et autorité de certification.
#   make scan DOCKER_NET=host CA_BUNDLE=/chemin/vers/bundle-complet.pem
# ----------------------------------------------------------------------------
DOCKER_NET  ?=
CA_BUNDLE   ?=
DOCKER_USER ?= $(shell id -u):$(shell id -g)

# Cache partagé (base Trivy, providers Terraform, archive d'image), hors de l'arbre git.
CACHE ?= $(CURDIR)/.cache
$(shell mkdir -p "$(CACHE)/trivy" "$(CACHE)/terraform/plugins")

CA_FLAGS := $(if $(CA_BUNDLE),-v "$(CA_BUNDLE)":/etc/ssl/lab-ca.pem:ro \
  -e SSL_CERT_FILE=/etc/ssl/lab-ca.pem -e REQUESTS_CA_BUNDLE=/etc/ssl/lab-ca.pem -e PIP_CERT=/etc/ssl/lab-ca.pem)
NET_FLAGS := $(if $(DOCKER_NET),--network $(DOCKER_NET))
RUN := docker run --rm $(NET_FLAGS) --user $(DOCKER_USER) -e HOME=/tmp \
  -e HTTPS_PROXY -e https_proxy -e NO_PROXY -e no_proxy $(CA_FLAGS) \
  -v "$(CURDIR)":/src -v "$(CACHE)":/cache -w /src

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
	rm -rf $(REPORTS) "$(CACHE)"

# ----------------------------------------------------------------------------
# Étape 1 : pipeline minimal
# ----------------------------------------------------------------------------
.PHONY: lint-workflows
lint-workflows: ## [À FAIRE] Vérifie la syntaxe des workflows GitHub Actions (actionlint)
	@echo "lint-workflows : non implémenté (docs/etapes/01-pipeline-minimal.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 2 : tests et image Docker
# ----------------------------------------------------------------------------
.PHONY: test
test: ## [À FAIRE] Lance les tests unitaires de l'application (pytest)
	@echo "test : non implémenté (docs/etapes/02-build-test-docker.md)"; exit 1

.PHONY: build
build: ## [À FAIRE] Construit l'image Docker de l'application
	@echo "build : non implémenté (docs/etapes/02-build-test-docker.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 3 : secrets
# ----------------------------------------------------------------------------
.PHONY: secrets
secrets: ## [À FAIRE] Cherche des secrets dans tout l'historique git (Gitleaks) : bloque toujours
	@echo "secrets : non implémenté (docs/etapes/03-secrets.md)"; exit 1

.PHONY: secrets-staged
secrets-staged: ## [À FAIRE] Cherche des secrets dans les fichiers indexés (utilisé par le hook pre-commit)
	@echo "secrets-staged : non implémenté (docs/etapes/03-secrets.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 4 : SAST (ton code) et SCA (tes dépendances)
# ----------------------------------------------------------------------------
.PHONY: sast
sast: ## [À FAIRE] Analyse statique du code (Semgrep) : bloque sur la sévérité ERROR
	@echo "sast : non implémenté (docs/etapes/04-sast-sca.md)"; exit 1

.PHONY: sca
sca: ## [À FAIRE] Dépendances vulnérables (Trivy fs) : bloque sur HIGH/CRITICAL avec correctif
	@echo "sca : non implémenté (docs/etapes/04-sast-sca.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 5 : image Docker
# ----------------------------------------------------------------------------
.PHONY: image-scan
image-scan: ## [À FAIRE] Scanne l'image (paquets OS, dépendances, secrets, configuration)
	@echo "image-scan : non implémenté (docs/etapes/05-image.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 6 : Terraform (fmt, validate, plan sans compte AWS)
# ----------------------------------------------------------------------------
.PHONY: tf-fmt
tf-fmt: ## [À FAIRE] Vérifie le formatage Terraform (terraform fmt -check)
	@echo "tf-fmt : non implémenté (docs/etapes/06-terraform.md)"; exit 1

.PHONY: tf-validate
tf-validate: ## [À FAIRE] Valide la syntaxe et la cohérence du code Terraform
	@echo "tf-validate : non implémenté (docs/etapes/06-terraform.md)"; exit 1

.PHONY: plan
plan: ## [À FAIRE] terraform plan sans compte AWS, exporté dans reports/tfplan.json
	@echo "plan : non implémenté (docs/etapes/06-terraform.md)"; exit 1

.PHONY: tf-lock
tf-lock: ## [À FAIRE] Régénère .terraform.lock.hcl (à lancer après un changement de version de provider)
	@echo "tf-lock : non implémenté (docs/etapes/06-terraform.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 7 : scan IaC et policies maison
# ----------------------------------------------------------------------------
.PHONY: iac-trivy
iac-trivy: ## [À FAIRE] Mauvaises configurations Terraform et Dockerfile (Trivy config)
	@echo "iac-trivy : non implémenté (docs/etapes/07-iac-policies.md)"; exit 1

.PHONY: iac-checkov
iac-checkov: ## [À FAIRE] Mauvaises configurations Terraform et Dockerfile (Checkov)
	@echo "iac-checkov : non implémenté (docs/etapes/07-iac-policies.md)"; exit 1

.PHONY: iac
iac: ## [À FAIRE] Les deux scanners IaC
	@echo "iac : non implémenté (docs/etapes/07-iac-policies.md)"; exit 1

.PHONY: policy-test
policy-test: ## [À FAIRE] Tests unitaires des policies Rego (conftest verify)
	@echo "policy-test : non implémenté (docs/etapes/07-iac-policies.md)"; exit 1

.PHONY: policy
policy: ## [À FAIRE] Applique les policies maison au plan Terraform (Conftest / OPA)
	@echo "policy : non implémenté (docs/etapes/07-iac-policies.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 8 : quality gates, exceptions, synthèse et démonstration
# ----------------------------------------------------------------------------
.PHONY: exceptions
exceptions: ## [À FAIRE] Vérifie que chaque exception est justifiée, datée et non expirée
	@echo "exceptions : non implémenté (docs/etapes/08-quality-gates.md)"; exit 1

.PHONY: scan
scan: ## [À FAIRE] Lance tous les quality gates et affiche une synthèse (ne s'arrête pas au premier échec)
	@echo "scan : non implémenté (docs/etapes/08-quality-gates.md)"; exit 1

.PHONY: summary
summary: ## [À FAIRE] Construit reports/summary.md à partir des résultats et des rapports SARIF
	@echo "summary : non implémenté (docs/etapes/08-quality-gates.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 10 : AWS réel
# ----------------------------------------------------------------------------
.PHONY: aws-plan
aws-plan: ## [À FAIRE] [AWS] terraform plan contre le vrai compte, en lecture seule
	@echo "aws-plan : non implémenté (docs/etapes/10-oidc-deploy.md)"; exit 1

.PHONY: aws-apply
aws-apply: ## [À FAIRE] [AWS] terraform apply (exige AWS_CONFIRM=oui)
	@echo "aws-apply : non implémenté (docs/etapes/10-oidc-deploy.md)"; exit 1

.PHONY: aws-destroy
aws-destroy: ## [À FAIRE] [AWS] terraform destroy de l'environnement dev (exige AWS_CONFIRM=oui)
	@echo "aws-destroy : non implémenté (docs/etapes/10-oidc-deploy.md)"; exit 1

# ----------------------------------------------------------------------------
# Étape 11 : SBOM et audit de posture du compte (CSPM)
# ----------------------------------------------------------------------------
.PHONY: sbom
sbom: ## [À FAIRE] Inventaire des composants de l'image (SBOM CycloneDX)
	@echo "sbom : non implémenté (docs/etapes/11-prowler-sbom.md)"; exit 1

.PHONY: sbom-scan
sbom-scan: ## [À FAIRE] Recherche de vulnérabilités à partir du SBOM seul, sans l'image
	@echo "sbom-scan : non implémenté (docs/etapes/11-prowler-sbom.md)"; exit 1

.PHONY: prowler
prowler: ## [À FAIRE] [AWS] Audit de posture du compte en lecture seule (Prowler), rapport dans reports/prowler/
	@echo "prowler : non implémenté (docs/etapes/11-prowler-sbom.md)"; exit 1

# === Vérifications du parcours (fourni, ne pas modifier) ===
include checks/checks.mk
