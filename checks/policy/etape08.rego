# Étape 8 : contrôles de structure du job security-gate et du commentaire de PR.
package e08.workflow

import rego.v1

import data.chk

gate := object.get(chk.jobs, "security-gate", {})

deny contains "[C1] le job exceptions est absent ou n'appelle pas sa cible make|jobs:" if {
	not contains(chk.script(object.get(chk.jobs, "exceptions", {})), "make exceptions")
}

deny contains "[C4] le job security-gate est absent|jobs:" if not chk.jobs["security-gate"]

deny contains "[C4] le job security-gate peut être sauté quand un contrôle échoue|  security-gate:" if {
	not contains(object.get(gate, "if", ""), "always()")
}

requis := {"workflow-lint", "build-test", "secrets", "sast", "sca", "image", "iac", "exceptions"}

deny contains msg if {
	some j in requis
	not j in {n | some n in object.get(gate, "needs", [])}
	msg := sprintf("[C5] le job security-gate ne dépend pas du contrôle %s|  security-gate:", [j])
}

deny contains "[C8] le job qui commente la PR n'a pas le droit de le faire|  security-gate:" if {
	object.get(chk.perms(gate), "pull-requests", "") != "write"
}

deny contains msg if {
	some name, job in chk.jobs
	name != "security-gate"
	object.get(chk.perms(job), "pull-requests", "none") == "write"
	msg := sprintf("[C8] le job %s peut écrire sur les pull requests sans en avoir besoin|  %s:", [name, name])
}

deny contains "[C8] le commentaire n'est pas réservé aux pull requests du dépôt lui-même|  security-gate:" if {
	count([s | some s in chk.steps(gate); contains(object.get(s, "if", ""), "head.repo.full_name == github.repository")]) == 0
}

deny contains msg if {
	some name, job in chk.jobs
	regex.match(`\$\{\{\s*github\.(event\.pull_request\.(title|body|head\.ref|head\.label)|head_ref)`, chk.script(job))
	msg := sprintf("[C9] le job %s insère une donnée non fiable de la PR dans un script|github.event.pull_request", [name])
}
