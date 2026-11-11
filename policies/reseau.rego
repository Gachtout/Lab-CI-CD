# Réseau : aucune règle entrante ouverte à tout Internet.
package lab.reseau

import rego.v1

import data.lib

monde := {"0.0.0.0/0", "::/0"}

# Forme moderne : une ressource par règle.
deny contains msg if {
	some rc in lib.changes
	rc.type == "aws_vpc_security_group_ingress_rule"
	some champ in ["cidr_ipv4", "cidr_ipv6"]
	object.get(rc.change.after, champ, null) in monde
	msg := sprintf("[NET-01] %s : entrée ouverte à tout Internet (%s)", [rc.address, rc.change.after[champ]])
}

# Forme historique : aws_security_group_rule.
deny contains msg if {
	some rc in lib.changes
	rc.type == "aws_security_group_rule"
	rc.change.after.type == "ingress"
	some champ in ["cidr_blocks", "ipv6_cidr_blocks"]
	some cidr in object.get(rc.change.after, champ, [])
	cidr in monde
	msg := sprintf("[NET-01] %s : entrée ouverte à tout Internet (%s)", [rc.address, cidr])
}

# Forme historique : blocs ingress dans aws_security_group.
deny contains msg if {
	some rc in lib.changes
	rc.type == "aws_security_group"
	some regle in object.get(rc.change.after, "ingress", [])
	some champ in ["cidr_blocks", "ipv6_cidr_blocks"]
	some cidr in object.get(regle, champ, [])
	cidr in monde
	msg := sprintf("[NET-01] %s : entrée ouverte à tout Internet (%s)", [rc.address, cidr])
}
