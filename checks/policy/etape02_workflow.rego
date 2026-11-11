package e02.workflow

import rego.v1

import data.chk

deny contains "[C7] le job build-test est absent|jobs:" if not chk.jobs["build-test"]

deny contains msg if {
	some cible in {"make test", "make build"}
	not contains(chk.script(chk.jobs["build-test"]), cible)
	msg := sprintf("[C7] le job build-test n'appelle pas `%s`|  build-test:", [cible])
}
