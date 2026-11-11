# Tags : toute ressource qui accepte des tags doit porter les tags obligatoires.
# C'est la règle type qu'aucun scanner ne fournit : elle dépend de l'organisation.
package lab.tags

import rego.v1

import data.lib

obligatoires := {"Project", "Environment", "Owner", "ManagedBy"}

deny contains msg if {
	some rc in lib.changes
	tags := rc.change.after.tags_all
	manquants := obligatoires - {cle | some cle, _ in tags}
	count(manquants) > 0
	msg := sprintf("[TAG-01] %s : tags obligatoires manquants %v", [rc.address, sort(manquants)])
}
