package e03.workflow

import rego.v1

import data.chk

deny contains "[C7] le job secrets est absent|jobs:" if not chk.jobs.secrets

deny contains "[C7] le job secrets n'appelle pas `make secrets`|  secrets:" if {
	not contains(chk.script(chk.jobs.secrets), "make secrets")
}

deny contains "[C7] le job secrets ne récupère pas tout l'historique|  secrets:" if {
	count([s | some s in chk.steps(chk.jobs.secrets); startswith(s.uses, "actions/checkout@"); s["with"]["fetch-depth"] == 0]) == 0
}
