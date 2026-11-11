package e06.workflow

import rego.v1

import data.chk

deny contains "[C8] le job plan est absent|jobs:" if not chk.jobs.plan

deny contains "[C8] le workflow ne se déclenche pas sur les pull requests|on:" if not chk.has_trigger("pull_request")

deny contains "[C8] le workflow utilise un déclencheur qui donne accès aux secrets depuis une PR|pull_request_target" if {
	chk.has_trigger("pull_request_target")
}

deny contains msg if {
	some name, job in chk.jobs
	object.get(chk.perms(job), "id-token", "none") != "none"
	msg := sprintf("[C8] le job %s peut demander un jeton d'identité cloud|  %s:", [name, name])
}

deny contains msg if {
	some cible in {"make tf-fmt", "make tf-validate"}
	not contains(chk.script(chk.jobs.plan), cible)
	msg := sprintf("[C8] le job plan n'appelle pas `%s`|  plan:", [cible])
}

deny contains "[C8] le job plan ne produit pas de plan|  plan:" if {
	not contains(chk.script(chk.jobs.plan), "make plan")
	not contains(chk.script(chk.jobs.plan), "make policy")
}
