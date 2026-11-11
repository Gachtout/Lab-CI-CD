# Étape 7 : contrôles de structure des workflows.
package e07.workflow

import rego.v1

import data.chk

deny contains "[C10] le job iac est absent|jobs:" if not chk.jobs.iac

deny contains msg if {
	some outil in {"iac-trivy", "iac-checkov"}
	not contains(chk.script(chk.jobs.iac), sprintf("make %s", [outil]))
	not regex.match(`make iac(\s|$)`, chk.script(chk.jobs.iac))
	msg := sprintf("[C10] le job iac ne lance pas le scanner %s|  iac:", [outil])
}
