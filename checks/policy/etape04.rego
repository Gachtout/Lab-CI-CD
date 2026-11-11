# Étape 4 : contrôles de structure des jobs sast et sca.
package e04.workflow

import rego.v1

import data.chk

deny contains msg if {
	some j in {"sast", "sca"}
	not chk.jobs[j]
	msg := sprintf("[C8] le job %s est absent|jobs:", [j])
}

deny contains msg if {
	some j in {"sast", "sca"}
	not contains(chk.script(chk.jobs[j]), sprintf("make %s", [j]))
	msg := sprintf("[C8] le job %s n'appelle pas sa cible make|  %s:", [j, j])
}

deny contains msg if {
	some name, job in chk.jobs
	some s in chk.steps(job)
	contains(s.uses, "/upload-sarif@")
	object.get(s, "continue-on-error", false) != true
	msg := sprintf("[C8] dans le job %s, l'envoi du rapport peut faire échouer le contrôle|  %s:", [name, name])
}

deny contains msg if {
	some name, job in chk.jobs
	some s in chk.steps(job)
	contains(s.uses, "/upload-sarif@")
	object.get(chk.perms(job), "security-events", "") != "write"
	msg := sprintf("[C8] le job %s envoie un rapport sans le droit correspondant|  %s:", [name, name])
}
