package e03.precommit

import rego.v1

entries := [h.entry | some r in object.get(input, "repos", []); some h in object.get(r, "hooks", [])]

deny contains "[C6] aucun hook n'appelle la cible qui scanne les fichiers indexés|repos:" if {
	count([e | some e in entries; contains(e, "make secrets-staged")]) == 0
}
