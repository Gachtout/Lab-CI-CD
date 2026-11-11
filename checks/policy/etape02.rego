# Étape 2 : contrôles de structure du Dockerfile et du job build-test.
package e02.dockerfile

import rego.v1

deny contains msg if {
	some i in input
	i.Cmd == "from"
	not contains(i.Value[0], "@sha256:")
	msg := sprintf("[C1] image de base non épinglée par digest|FROM %s", [i.Value[0]])
}

users := [i.Value[0] | some i in input; i.Cmd == "user"]

deny contains "[C2] aucun utilisateur d'exécution n'est déclaré|FROM" if count(users) == 0

deny contains "[C2] l'utilisateur d'exécution final est root|USER" if {
	count(users) > 0
	lower(users[count(users) - 1]) in {"root", "0", "0:0", "root:root"}
}

deny contains "[C3] aucun contrôle de santé n'est déclaré|FROM" if {
	count([i | some i in input; i.Cmd == "healthcheck"]) == 0
}

deny contains "[C4] une installation pip conserve son cache dans l'image|pip install" if {
	some i in input
	i.Cmd == "run"
	contains(i.Value[0], "pip install")
	not contains(i.Value[0], "--no-cache-dir")
}
