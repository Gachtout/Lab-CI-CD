# Vérifications du parcours. Fichier fourni : ne pas le modifier.
# Inclus à la fin du Makefile ; utilise la variable RUN et l'image Conftest de la plomberie.

.PHONY: __conftest
__conftest:
	@$(RUN) $(CONFTEST_IMAGE) $(A)

check-etape-%: ## Vérifie ton implémentation d'une étape (ex. make check-etape-03)
	@test -f checks/etape-$*.sh || { echo "Étape inconnue : $*. Étapes disponibles : 01 à 11."; exit 2; }
	@ETAPE=$* bash checks/etape-$*.sh

.PHONY: check-tout
check-tout: ## Vérifie toutes les étapes dans l'ordre, s'arrête à la première non validée
	@for n in 01 02 03 04 05 06 07 08 09 10 11; do \
	  echo "== Étape $$n"; ETAPE=$$n bash checks/etape-$$n.sh || exit 1; \
	done

.PHONY: test-checks
test-checks: ## [Mainteneur] Éprouve les vérifications : corrigé, squelette, mutants, progression
	@bash checks/tools/test-checks.sh

# Terraform hors ligne pour les vérifications : faux identifiants, aucune action possible sur un compte réel.
.PHONY: __terraform
__terraform:
	@$(RUN) -e TF_IN_AUTOMATION=1 -e CHECKPOINT_DISABLE=1 -e TF_PLUGIN_CACHE_DIR=/cache/terraform/plugins \
	  -e TF_DATA_DIR=/tmp/tfdata -e AWS_ACCESS_KEY_ID=offline -e AWS_SECRET_ACCESS_KEY=offline \
	  --entrypoint sh $(TERRAFORM_IMAGE) -c '$(A)'
