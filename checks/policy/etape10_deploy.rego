package e10.deploy

import rego.v1

import data.chk

aws_jobs contains name if {
	some name, job in chk.jobs
	some s in chk.steps(job)
	contains(s.uses, "configure-aws-credentials@")
}

deny contains "[C6] aucun job n'obtient d'identifiants AWS par fédération d'identité|jobs:" if count(aws_jobs) == 0

deny contains msg if {
	some name in aws_jobs
	object.get(chk.perms(chk.jobs[name]), "id-token", "") != "write"
	msg := sprintf("[C6] le job %s ne peut pas demander de jeton d'identité|  %s:", [name, name])
}

deny contains msg if {
	some name in aws_jobs
	not chk.jobs[name].environment
	msg := sprintf("[C7] le job %s obtient des identifiants AWS hors de tout environnement GitHub|  %s:", [name, name])
}

deny contains msg if {
	some t in {"pull_request", "pull_request_target"}
	chk.has_trigger(t)
	msg := sprintf("[C8] le déploiement peut être déclenché par %s|%s", [t, t])
}

deny contains "[C8] le déploiement automatique ne vise pas uniquement la branche main|push:" if {
	chk.has_trigger("push")
	object.get(object.get(chk.triggers, "push", {}), "branches", []) != ["main"]
}
