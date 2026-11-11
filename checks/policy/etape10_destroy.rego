package e10.destroy

import rego.v1

import data.chk

deny contains "[C7] la destruction peut être déclenchée autrement que manuellement|on:" if {
	is_object(chk.triggers)
	object.keys(chk.triggers) != {"workflow_dispatch"}
}

deny contains msg if {
	some name, job in chk.jobs
	not job.environment
	msg := sprintf("[C7] le job %s détruit hors de tout environnement GitHub|  %s:", [name, name])
}

deny contains msg if {
	some name, job in chk.jobs
	not contains(object.get(job, "if", ""), "inputs.")
	msg := sprintf("[C7] le job %s ne vérifie aucune confirmation saisie|  %s:", [name, name])
}

deny contains msg if {
	some name, job in chk.jobs
	object.get(chk.perms(job), "id-token", "") != "write"
	msg := sprintf("[C6] le job %s ne peut pas demander de jeton d'identité|  %s:", [name, name])
}
