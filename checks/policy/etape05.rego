# Étape 5 : contrôle de structure du job image.
package e05.workflow

import rego.v1

import data.chk

deny contains "[C6] le job image est absent|jobs:" if not chk.jobs.image

deny contains msg if {
	some cible in {"make build", "make image-scan"}
	not contains(chk.script(chk.jobs.image), cible)
	msg := sprintf("[C6] le job image n'appelle pas `%s`|  image:", [cible])
}
