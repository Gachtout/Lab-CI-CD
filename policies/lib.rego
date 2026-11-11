# Fonctions communes aux policies : elles lisent le plan Terraform exporté en JSON.
package lib

import rego.v1

# Ressources que le plan crée ou modifie (les suppressions et les lectures sont ignorées).
changes contains rc if {
	some rc in input.resource_changes
	rc.mode == "managed"
	some action in rc.change.actions
	action in {"create", "update"}
}

module_of(rc) := object.get(rc, "module_address", "racine")
