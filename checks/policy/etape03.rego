# Étape 3 : contrôles de structure (configuration Gitleaks, hook, job secrets).
package e03.gitleaks

import rego.v1

deny contains "[C2] aucune règle maison ne porte l'identifiant imposé|[[rules]]" if {
	count([r | some r in object.get(input, "rules", []); r.id == "lab-fake-token"]) == 0
}
