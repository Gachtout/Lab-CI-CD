# Étape 6 : contrôles de structure du plan Terraform et du workflow terraform-plan.
package e06.plan

import rego.v1

created contains rc.type if {
	some i
	rc := input.resource_changes[i]
	rc.mode == "managed"
	"create" in rc.change.actions
}

attendus := {
	"aws_vpc", "aws_subnet", "aws_security_group", "aws_s3_bucket",
	"aws_s3_bucket_public_access_block", "aws_iam_role",
}

deny contains msg if {
	some t in attendus
	not t in created
	msg := sprintf("[C4] le plan ne crée aucune ressource de type %s|", [t])
}

payants := {"aws_nat_gateway", "aws_instance", "aws_eip", "aws_db_instance", "aws_lb", "aws_kms_key", "aws_eks_cluster"}

deny contains msg if {
	some i
	rc := input.resource_changes[i]
	rc.type in payants
	"create" in rc.change.actions
	msg := sprintf("[C5] le plan crée une ressource payante : %s|", [rc.address])
}
