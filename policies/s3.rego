# S3 : aucun bucket ne doit pouvoir devenir public.
package lab.s3

import rego.v1

import data.lib

reglages := ["block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets"]

# Attention : un attribut absent vaut null dans le plan. On compare donc à true
# explicitement, au lieu d'écrire "not x" qui laisserait passer null.
deny contains msg if {
	some rc in lib.changes
	rc.type == "aws_s3_bucket_public_access_block"
	some reglage in reglages
	object.get(rc.change.after, reglage, null) != true
	msg := sprintf("[S3-01] %s : %s doit valoir true (accès public bloqué)", [rc.address, reglage])
}

deny contains msg if {
	some bucket in lib.changes
	bucket.type == "aws_s3_bucket"
	not a_un_blocage(bucket)
	msg := sprintf("[S3-02] %s : aucun aws_s3_bucket_public_access_block dans le même module", [bucket.address])
}

a_un_blocage(bucket) if {
	some rc in lib.changes
	rc.type == "aws_s3_bucket_public_access_block"
	lib.module_of(rc) == lib.module_of(bucket)
}
