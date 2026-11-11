package e07.planworkflow

import rego.v1

import data.chk

deny contains "[C10] le workflow terraform-plan n'applique pas les policies au plan|  plan:" if {
	not contains(chk.script(chk.jobs.plan), "make policy")
}
