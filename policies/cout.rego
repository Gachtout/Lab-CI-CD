# Coût : ce lab ne doit créer que des ressources gratuites.
package lab.cout

import rego.v1

import data.lib

payantes := {
	"aws_nat_gateway": "environ 30 € par mois, plus le trafic",
	"aws_instance": "hors périmètre du lab",
	"aws_eip": "facturée dès qu'elle n'est pas attachée",
	"aws_db_instance": "hors périmètre du lab",
	"aws_lb": "environ 16 € par mois",
	"aws_kms_key": "1 $ par mois et par clé",
	"aws_eks_cluster": "environ 70 € par mois",
}

deny contains msg if {
	some rc in lib.changes
	raison := payantes[rc.type]
	msg := sprintf("[COST-01] %s : type %s interdit dans ce lab (%s)", [rc.address, rc.type, raison])
}
