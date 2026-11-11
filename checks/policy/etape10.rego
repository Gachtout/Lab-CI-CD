# Étape 10 : contrôles de structure du plan du bootstrap (calculé hors ligne).
package e10.plan

import rego.v1

created(t) := [rc | some rc in input.resource_changes; rc.type == t; "create" in rc.change.actions]

oidc := created("aws_iam_openid_connect_provider")

deny contains "[C1] aucun fournisseur d'identité n'est créé pour l'émetteur de jetons de GitHub Actions|" if {
	count([p | some p in oidc; p.change.after.url == "https://token.actions.githubusercontent.com"]) == 0
}

deny contains "[C3] le fournisseur d'identité accepte une autre audience que celle d'AWS STS|" if {
	some p in oidc
	p.change.after.client_id_list != ["sts.amazonaws.com"]
}

deny contains msg if {
	some t in {"aws_s3_bucket_versioning", "aws_s3_bucket_server_side_encryption_configuration", "aws_s3_bucket_public_access_block"}
	count(created(t)) == 0
	msg := sprintf("[C4] le bucket d'état n'a pas de ressource %s|", [t])
}

deny contains "[C5] aucune alerte de budget n'est créée|" if count(created("aws_budgets_budget")) == 0
