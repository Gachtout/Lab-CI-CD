# Étape 6 : Terraform, format, validation et plan

## Objectif

Décrire une infrastructure AWS en code et obtenir, sur chaque pull request, la liste exacte de ce qui serait créé. Sans compte AWS pour l'instant.

## Le concept, depuis zéro

**Le problème.** Une infrastructure créée à la console n'a ni historique, ni relecture, ni moyen d'être rejouée. Personne ne sait pourquoi un port est ouvert.

**L'idée de Terraform.** On décrit l'état *voulu* dans des fichiers. Terraform compare trois choses :

| Élément | Rôle |
|---|---|
| Le **code** (`*.tf`) | Ce que tu veux |
| L'**état** (`terraform.tfstate`) | Ce que Terraform croit avoir créé |
| La **réalité** (les API AWS) | Ce qui existe vraiment |

`terraform plan` calcule la différence et l'affiche ; `terraform apply` l'exécute. Le plan est l'objet central pour la sécurité : c'est une **prédiction lisible par une machine** de chaque changement. On peut donc le contrôler avant qu'il ne se produise (étape 7).

**Trois contrôles, du moins cher au plus riche :**

1. `terraform fmt -check` : le code est-il formaté de façon standard ? Aucun appel réseau.
2. `terraform validate` : les références et les types sont-ils cohérents ? Charge les providers, n'appelle pas AWS.
3. `terraform plan` : que va-t-il se passer ? Normalement, interroge AWS.

**Un plan sans AWS.** Quand il n'existe encore aucune ressource et aucune source de données distante, le plan n'a rien à lire chez AWS. Avec trois options `skip_*` du provider et de faux identifiants, il se calcule donc hors ligne. Deux intérêts : le lab se rejoue sans compte, et une PR venant d'un fork peut être planifiée sans qu'on lui confie le moindre identifiant.

## Ce qu'on fait

```text
terraform/
├── modules/
│   ├── vpc/             VPC, sous-réseau privé, security group par défaut fermé
│   ├── security_group/  HTTPS entrant depuis des plages explicites
│   ├── s3/              bucket privé, chiffré, versionné, TLS obligatoire
│   └── iam/             rôle applicatif en lecture seule sur le bucket
└── envs/dev/            assemble les modules ; backend S3 (configuré à l'étape 10)
```

Tout est gratuit : ni EC2, ni NAT Gateway, ni base de données.

- `make tf-fmt`, `make tf-validate`, `make plan`.
- `terraform/envs/dev/.terraform.lock.hcl` est **commité** : il fige les empreintes du provider AWS (6.72.0), comme un digest d'image.
- Workflow `terraform-plan.yml` : les trois contrôles, puis un commentaire de PR avec le résumé du plan.
- Deux hooks pre-commit de plus : `terraform fmt` et `terraform validate`.

`make plan` travaille dans une copie temporaire, avec un backend local jetable : rien n'est écrit dans le dépôt, aucun état n'est conservé.

## Comment vérifier

```bash
make tf-fmt && make tf-validate && make plan
```

```text
Success! The configuration is valid.

  # module.app_role.aws_iam_role.app will be created
  # module.app_sg.aws_security_group.this will be created
  # module.app_sg.aws_vpc_security_group_ingress_rule.https["10.20.0.0/16"] will be created
  # module.data.aws_s3_bucket.this will be created
  # module.data.aws_s3_bucket_public_access_block.this will be created
  # module.vpc.aws_vpc.this will be created
  …
Plan: 15 to add, 0 to change, 0 to destroy.
```

Le plan complet est dans `reports/tfplan.txt`, et sa version machine dans `reports/tfplan.json`.

## Casse-le volontairement

### Format

Dans `terraform/modules/vpc/main.tf`, retire les espaces d'alignement de la ligne `cidr_block`.

```text
 resource "aws_vpc" "this" {
-  cidr_block = var.cidr
+  cidr_block           = var.cidr
make: *** [Makefile:143: tf-fmt] Error 3
```

### Validation

Dans `terraform/envs/dev/main.tf`, remplace `module.vpc.vpc_id` par `module.vpc.identifiant`.

```text
│ Error: Unsupported attribute
│   on main.tf line 15, in module "app_sg":
│   15:   vpc_id        = module.vpc.identifiant
│ This object does not have an attribute named "identifiant".
make: *** [Makefile:147: tf-validate] Error 1
```

### Ce que ces contrôles ne voient pas

Dans `terraform/envs/dev/variables.tf`, mets `["0.0.0.0/0"]` comme valeur par défaut de `app_ingress_cidrs`, puis relance les trois commandes. **Tout est vert.** Le code est bien formaté, valide, et le plan annonce sans broncher une règle ouverte au monde entier. Terraform vérifie que la demande est *cohérente*, pas qu'elle est *raisonnable*. C'est le rôle de l'étape 7.

Annule avec `git checkout terraform/`.

## Côté Wiz, en entreprise

`fmt`, `validate` et `plan` restent des commandes Terraform : Wiz ne les remplace pas. Ce que Wiz ajoute, c'est le scan du code ou du plan produit ici (`wizcli iac scan`). Le fichier de plan JSON de cette étape est donc l'entrée de l'étape suivante, avec Wiz comme avec les outils gratuits.
