# Étape 1 : contrôles de structure du workflow pr-security.
package e01.workflow

import rego.v1

import data.chk

deny contains msg if {
	some t in {"pull_request", "push", "workflow_dispatch"}
	not chk.has_trigger(t)
	msg := sprintf("[C1] déclencheur attendu absent : %s|on:", [t])
}

deny contains msg if {
	some t in {"pull_request", "push"}
	object.get(object.get(chk.triggers, t, {}), "branches", []) != ["main"]
	chk.has_trigger(t)
	msg := sprintf("[C1] le déclencheur %s ne vise pas uniquement la branche main|%s:", [t, t])
}

deny contains "[C2] le jeton du workflow a des droits par défaut|permissions:" if {
	object.get(input, "permissions", null) != {}
}

deny contains msg if {
	some name, job in chk.jobs
	not job.permissions
	msg := sprintf("[C2] le job %s ne déclare pas ses droits|  %s:", [name, name])
}

deny contains "[C2] le job workflow-lint a plus de droits que nécessaire|  workflow-lint:" if {
	chk.perms(chk.jobs["workflow-lint"]) != {"contents": "read"}
}

deny contains msg if {
	some job in chk.jobs
	some s in chk.steps(job)
	not startswith(s.uses, "./")
	not regex.match(`^[^@]+@[0-9a-f]{40}$`, s.uses)
	msg := sprintf("[C3] action non épinglée par SHA de commit complet|%s", [s.uses])
}

deny contains msg if {
	some name, job in chk.jobs
	some s in chk.steps(job)
	startswith(s.uses, "actions/checkout@")
	object.get(object.get(s, "with", {}), "persist-credentials", true) != false
	msg := sprintf("[C4] le jeton reste dans la configuration git du runner (job %s)|  %s:", [name, name])
}

deny contains "[C5] le job workflow-lint n'appelle pas la cible make attendue|  workflow-lint:" if {
	not contains(chk.script(chk.jobs["workflow-lint"]), "make lint-workflows")
}

deny contains "[C5] le job workflow-lint installe un outil au lieu d'appeler make|  workflow-lint:" if {
	regex.match(`(apt-get|pip3? install|curl |wget |brew )`, chk.script(chk.jobs["workflow-lint"]))
}

artifact_ok if {
	some s in chk.steps(chk.jobs["workflow-lint"])
	startswith(s.uses, "actions/upload-artifact@")
	contains(object.get(s, "if", ""), "always()")
	s["with"]["retention-days"] == 7
}

deny contains "[C6] le rapport n'est pas publié en toutes circonstances, ou pas conservé 7 jours|  workflow-lint:" if {
	not artifact_ok
}

deny contains msg if {
	some name, job in chk.jobs
	not job["timeout-minutes"]
	msg := sprintf("[C7] le job %s n'a pas de durée maximale|  %s:", [name, name])
}

deny contains "[C8] une nouvelle exécution n'annule pas la précédente|concurrency:" if {
	object.get(object.get(input, "concurrency", {}), "cancel-in-progress", false) != true
}
