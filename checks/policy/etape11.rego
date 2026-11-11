# Étape 11 : contrôle de structure du job sbom.
package e11.workflow

import rego.v1

import data.chk

job := object.get(chk.jobs, "sbom", {})

deny contains "[C4] le job sbom est absent ou n'appelle pas sa cible make|jobs:" if {
	not contains(chk.script(job), "make sbom")
}

deny contains "[C4] le job sbom s'exécute aussi sur les pull requests|  sbom:" if {
	not contains(object.get(job, "if", ""), "pull_request")
}

deny contains "[C4] l'inventaire n'est pas conservé au moins 30 jours|  sbom:" if {
	count([s | some s in chk.steps(job); startswith(s.uses, "actions/upload-artifact@"); s["with"]["retention-days"] >= 30]) == 0
}
