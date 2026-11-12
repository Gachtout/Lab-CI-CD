# Banc de test des vérifications du parcours (branche `banc`). Voir README.md.
.PHONY: test-checks
test-checks: ## Éprouve les vérifications de la branche exercices contre la branche solution
	@bash tools/test-checks.sh

.PHONY: fuites
fuites: ## Ne lance que la cohérence et la recherche de fuite (quelques secondes)
	@PARTS=statique bash tools/test-checks.sh
