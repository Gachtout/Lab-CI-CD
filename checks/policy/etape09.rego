# Étape 9 : contrôles de structure du ruleset (aucun appel à GitHub).
package e09.ruleset

import rego.v1

types := {r.type | some r in object.get(input, "rules", [])}

deny contains "[C1] le ruleset n'est pas actif sur les branches|\"enforcement\"" if {
	not {input.target, input.enforcement} == {"branch", "active"}
}

deny contains "[C1] le ruleset ne vise pas la branche par défaut|\"include\"" if {
	cibles := {c | some c in object.get(object.get(object.get(input, "conditions", {}), "ref_name", {}), "include", [])}
	count(cibles & {"~DEFAULT_BRANCH", "refs/heads/main"}) == 0
}

deny contains "[C2] un acteur peut contourner le ruleset|\"bypass_actors\"" if {
	count(object.get(input, "bypass_actors", ["absent"])) > 0
}

deny contains msg if {
	some t in {"deletion", "non_fast_forward"}
	not t in types
	msg := sprintf("[C3] règle attendue absente : %s|\"rules\"", [t])
}

deny contains "[C4] une modification peut atteindre la branche sans pull request|\"rules\"" if {
	not "pull_request" in types
}

contexts := {c.context |
	some r in object.get(input, "rules", [])
	r.type == "required_status_checks"
	some c in r.parameters.required_status_checks
}

deny contains msg if {
	some c in {"security-gate", "plan"}
	not c in contexts
	msg := sprintf("[C5] statut requis absent : %s|\"required_status_checks\"", [c])
}

deny contains "[C5] une branche en retard sur main peut être fusionnée|\"required_status_checks\"" if {
	some r in object.get(input, "rules", [])
	r.type == "required_status_checks"
	object.get(r.parameters, "strict_required_status_checks_policy", false) != true
}
