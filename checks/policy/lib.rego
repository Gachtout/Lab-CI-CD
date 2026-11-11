# Fonctions communes aux contrôles de structure des workflows.
# Dans un workflow lu comme YAML, la clé "on" devient "true".
package chk

import rego.v1

jobs := object.get(input, "jobs", {})

triggers := object.get(input, "true", {})

has_trigger(name) if {
	is_object(triggers)
	_ := triggers[name]
}
has_trigger(name) if {
	is_array(triggers)
	name in triggers
}
has_trigger(name) if triggers == name

steps(job) := object.get(job, "steps", [])

script(job) := concat("\n", [s.run | some s in steps(job); s.run])

all_scripts := concat("\n", [script(j) | some j in jobs])

perms(job) := object.get(job, "permissions", {})
