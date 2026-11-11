# Tests unitaires des policies : make policy-test
package lab_test

import rego.v1

import data.lab.cout
import data.lab.reseau
import data.lab.s3
import data.lab.tags

tags_ok := {"Project": "p", "Environment": "dev", "Owner": "o", "ManagedBy": "terraform"}

plan(ressources) := {"resource_changes": ressources}

ressource(type, after) := {
	"address": sprintf("%s.test", [type]),
	"mode": "managed",
	"type": type,
	"change": {"actions": ["create"], "after": after},
}

blocage_ok := ressource("aws_s3_bucket_public_access_block", {
	"block_public_acls": true,
	"block_public_policy": true,
	"ignore_public_acls": true,
	"restrict_public_buckets": true,
})

bucket := ressource("aws_s3_bucket", {"tags_all": tags_ok})

test_bucket_prive_accepte if {
	count(s3.deny) == 0 with input as plan([bucket, blocage_ok])
}

test_bucket_public_refuse if {
	public := json.patch(blocage_ok, [{"op": "replace", "path": "/change/after/block_public_policy", "value": false}])
	some msg in s3.deny with input as plan([bucket, public])
	contains(msg, "S3-01")
}

test_reglage_absent_refuse if {
	# null ne doit pas passer pour "vrai"
	absent := json.patch(blocage_ok, [{"op": "replace", "path": "/change/after/ignore_public_acls", "value": null}])
	some msg in s3.deny with input as plan([bucket, absent])
	contains(msg, "ignore_public_acls")
}

test_bucket_sans_blocage_refuse if {
	some msg in s3.deny with input as plan([bucket])
	contains(msg, "S3-02")
}

test_entree_interne_acceptee if {
	regle := ressource("aws_vpc_security_group_ingress_rule", {"cidr_ipv4": "10.20.0.0/16", "cidr_ipv6": null})
	count(reseau.deny) == 0 with input as plan([regle])
}

test_entree_monde_refusee if {
	regle := ressource("aws_vpc_security_group_ingress_rule", {"cidr_ipv4": "0.0.0.0/0", "cidr_ipv6": null})
	some msg in reseau.deny with input as plan([regle])
	contains(msg, "NET-01")
}

test_entree_monde_ipv6_refusee if {
	regle := ressource("aws_vpc_security_group_ingress_rule", {"cidr_ipv4": null, "cidr_ipv6": "::/0"})
	count(reseau.deny) == 1 with input as plan([regle])
}

test_bloc_ingress_historique_refuse if {
	sg := ressource("aws_security_group", {"ingress": [{"cidr_blocks": ["0.0.0.0/0"], "ipv6_cidr_blocks": []}]})
	count(reseau.deny) == 1 with input as plan([sg])
}

test_tags_complets_acceptes if {
	count(tags.deny) == 0 with input as plan([bucket])
}

test_tag_manquant_refuse if {
	sans_owner := ressource("aws_vpc", {"tags_all": object.remove(tags_ok, ["Owner"])})
	some msg in tags.deny with input as plan([sans_owner])
	contains(msg, "Owner")
}

test_ressource_sans_tags_ignoree if {
	# Les ressources qui n'acceptent pas de tags n'ont pas d'attribut tags_all.
	count(tags.deny) == 0 with input as plan([blocage_ok])
}

test_nat_gateway_refusee if {
	nat := ressource("aws_nat_gateway", {"tags_all": tags_ok})
	some msg in cout.deny with input as plan([nat])
	contains(msg, "COST-01")
}

test_suppression_ignoree if {
	# Détruire une ressource interdite doit rester possible.
	nat := json.patch(ressource("aws_nat_gateway", null), [{"op": "replace", "path": "/change/actions", "value": ["delete"]}])
	count(cout.deny) == 0 with input as plan([nat])
}
