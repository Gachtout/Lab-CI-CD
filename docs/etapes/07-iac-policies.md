# Étape 7 : scan IaC et policies maison

## Objectif

Refuser une infrastructure dangereuse **avant** qu'elle n'existe, avec deux scanners du marché et des règles écrites par toi.

## Le concept, depuis zéro

À l'étape 6, Terraform a accepté un security group ouvert au monde entier : la demande était cohérente. Il manque quelqu'un pour dire qu'elle est mauvaise. Deux façons de le faire, qui ne voient pas la même chose.

| | Analyse **statique** du code | Analyse du **plan** |
|---|---|---|
| Entrée | Les fichiers `*.tf` | `tfplan.json`, produit par `terraform plan` |
| Outils ici | Trivy config, Checkov | Conftest (moteur OPA, langage Rego) |
| Avantage | Immédiate, aucun `init`, pointe la ligne fautive | Voit les **valeurs finales**, après variables, boucles et modules |
| Limite | Doit deviner la valeur des variables et des `for_each` | Demande un plan, donc un `init` et des providers |

**Pourquoi des règles maison ?** Les scanners embarquent des centaines de règles génériques (« un bucket ne doit pas être public »). Ils ne connaissent pas *tes* règles : tags obligatoires, types de ressources interdits, régions autorisées. Une policy-as-code est une règle interne écrite dans un langage exécutable, versionnée et testée comme du code.

**Rego en trois idées :**

- Une règle `deny contains msg if { … }` ajoute un message à l'ensemble `deny` quand **toutes** les lignes du bloc sont vraies.
- `some rc in input.resource_changes` parcourt le plan.
- Piège classique : un attribut absent vaut `null` dans le plan, et `not x` est faux quand `x` vaut `null`. On compare donc explicitement : `x != true`.

## Ce qu'on fait

| Fichier | Rôle |
|---|---|
| `make iac-trivy` | Trivy config sur Terraform et le `Dockerfile` : bloque sur `HIGH` et `CRITICAL` |
| `make iac-checkov` | Checkov : bloque sur tout contrôle en échec non explicitement écarté |
| `policies/s3.rego` | `S3-01`, `S3-02` : les quatre blocages d'accès public à `true`, sur chaque bucket |
| `policies/reseau.rego` | `NET-01` : aucune entrée depuis `0.0.0.0/0` ou `::/0` |
| `policies/tags.rego` | `TAG-01` : tags `Project`, `Environment`, `Owner`, `ManagedBy` |
| `policies/cout.rego` | `COST-01` : pas de NAT Gateway, EC2, RDS, KMS… dans ce lab |
| `policies/policies_test.rego` | 13 tests unitaires des policies |
| `make policy` | Plan hors ligne, tests des policies, puis application au plan |

Le premier passage des scanners sur le code sain a remonté 1 constat `HIGH` côté Trivy et 6 échecs côté Checkov, tous discutables pour un lab gratuit (clé KMS, journaux d'accès, flow logs…). Ils sont traités comme des **exceptions justifiées et datées**, pas ignorés en silence : voir l'étape 8.

## Comment vérifier

```bash
make iac && make policy
```

```text
Passed checks: 70, Failed checks: 0, Skipped checks: 4

13 tests, 13 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped

7 tests, 7 passed, 0 warnings, 0 failures, 0 exceptions
```

## Casse-le volontairement

Applique les deux changements de la future PR « bad » :

- `terraform/envs/dev/variables.tf` : `app_ingress_cidrs` passe à `["0.0.0.0/0"]` ;
- `terraform/envs/dev/main.tf` : `block_public_access = false`.

### Trivy config

```text
Failures: 4 (HIGH: 4, CRITICAL: 0)
AWS-0086 (HIGH): Public access block does not block public ACLs
AWS-0087 (HIGH): Public access block does not block public policies
AWS-0091 (HIGH): Public access block does not ignore public ACLs
AWS-0093 (HIGH): Public access block does not restrict public buckets
make: *** [Makefile:183: iac-trivy] Error 1
```

### Checkov

```text
Check: CKV_AWS_53: "Ensure S3 bucket has block public ACLS enabled"
Check: CKV_AWS_54: "Ensure S3 bucket has block public policy enabled"
Check: CKV_AWS_55: "Ensure S3 bucket has ignore public ACLs enabled"
Check: CKV_AWS_56: "Ensure S3 bucket has 'restrict_public_buckets' enabled"
Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
Passed checks: 65, Failed checks: 5, Skipped checks: 4
make: *** [Makefile:188: iac-checkov] Error 1
```

### Policies sur le plan

```text
FAIL - reports/tfplan.json - lab.s3 - [S3-01] module.data.aws_s3_bucket_public_access_block.this : block_public_acls doit valoir true (accès public bloqué)
FAIL - reports/tfplan.json - lab.s3 - [S3-01] … : block_public_policy doit valoir true (accès public bloqué)
FAIL - reports/tfplan.json - lab.s3 - [S3-01] … : ignore_public_acls doit valoir true (accès public bloqué)
FAIL - reports/tfplan.json - lab.s3 - [S3-01] … : restrict_public_buckets doit valoir true (accès public bloqué)
FAIL - reports/tfplan.json - lab.reseau - [NET-01] module.app_sg.aws_vpc_security_group_ingress_rule.https["0.0.0.0/0"] : entrée ouverte à tout Internet (0.0.0.0/0)
9 tests, 4 passed, 0 warnings, 5 failures, 0 exceptions
make: *** [Makefile:200: policy] Error 1
```

### Le résultat à retenir

Relis les trois sorties : **ni Trivy ni Checkov n'ont signalé le security group ouvert.** Le bucket public, oui ; la règle `0.0.0.0/0`, non. La plage vient d'une variable, consommée par un `for_each` dans un module : l'analyse statique n'a pas reconstitué la valeur. Seule la policy appliquée au plan l'a vue, parce que le plan contient la valeur finale.

Ce n'est pas un défaut de configuration, c'est une limite de méthode. Deux leçons :

- « Le scanner est vert » ne veut pas dire « c'est sûr ». Il faut savoir ce que l'outil est capable de voir.
- Pour les règles qui comptent vraiment, contrôler le **plan** est plus fiable que contrôler le code.

Dernier essai : ajoute une ressource `aws_nat_gateway` dans `envs/dev/main.tf` et relance `make policy` pour voir `COST-01`. Annule avec `git checkout terraform/`.

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| Trivy config, Checkov | `wizcli iac scan` sur le répertoire, avec les règles de configuration cloud de Wiz |
| Conftest sur `tfplan.json` | `wizcli iac scan` accepte aussi un plan Terraform JSON : même bénéfice des valeurs résolues |
| Policies Rego dans `policies/` | Règles de configuration cloud personnalisées, écrites **en Rego** dans la console |
| Tests `conftest verify` | Pas d'équivalent intégré : garder des tests unitaires de ses règles reste une bonne pratique |

Le Rego appris ici est donc directement réutilisable. La structure d'entrée diffère (Wiz expose sa propre représentation de la ressource), la logique `deny si…` est la même.
