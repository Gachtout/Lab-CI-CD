# Rapport de validation

Banc lancé le 2026-11-12 depuis la branche `banc`, sur `exercices` (`ad96e7a`) et `solution` (`c9fa885`).
Instantané : relance `make test-checks` après toute modification.

## Résultat

- 11 étapes : chaque vérification passe sur le corrigé et échoue sur le squelette.
- 87 mutants, tous détectés par la contrainte attendue.
- Progression, N = 1 à 10 : 20 cas sur 20.
- Cohérence : 86 contraintes, chacune avec au moins un contrôle et un mutant.
- Fuite : 494 lignes et 792 littéraux du corrigé cherchés dans 75 fichiers ; 442 occurrences trouvées, toutes classées, 0 fuite.
- Séparation : aucun fichier ni cible de mainteneur sur `exercices`.

## Ce que la recherche de fuite ne garantit pas

1. **« Nécessaire au check » est une divulgation assumée.** Un contrôle qui cherche un champ révèle que ce champ est attendu. C'est le plus net à l'étape 9 (les contrôles nomment les champs du ruleset) et à l'étape 10 (la vérification planifie le bootstrap hors ligne avec de faux identifiants, ce qui montre la technique à trouver à l'étape 6).
2. **Fragments courts.** Hors des pages, un littéral de moins de 12 caractères n'est pas cherché. Des mots comme `fetch-depth`, `id-token` ou `StringLike` figurent dans des contrôles sans apparaître dans ce rapport.
3. **Prose.** Un indice de niveau 3 qui décrit la réponse sans la citer n'est pas détecté. Les sections « concept » viennent du corrigé et décrivent certains de ses choix.
4. **Plans de référence.** Les fichiers de `checks/fixtures/` montrent la structure d'un plan et les noms d'attributs que les policies de l'étape 7 doivent lire. C'est voulu (donnée d'entrée de l'exercice), mais c'est une aide.
5. **Historique git.** La branche `exercices` descend de `main` et son historique contient le corrigé, ainsi que l'ancien commit où les mutants y figuraient. La procédure d'import du README supprime l'historique.

Les autres limites (étapes 9 et 10 en statique, cibles `aws-*` et `prowler` jamais exécutées, dépendance aux CVE du jour, environnement de validation) sont inchangées.

## Fichiers retirés de la branche `exercices`

- `checks/RAPPORT-VALIDATION.md`
- `checks/mutants/etape_01.py`
- `checks/mutants/etape_02.py`
- `checks/mutants/etape_03.py`
- `checks/mutants/etape_04.py`
- `checks/mutants/etape_05.py`
- `checks/mutants/etape_06.py`
- `checks/mutants/etape_07.py`
- `checks/mutants/etape_08.py`
- `checks/mutants/etape_09.py`
- `checks/mutants/etape_10.py`
- `checks/mutants/etape_11.py`
- `checks/tools/coherence.py`
- `checks/tools/leak.py`
- `checks/tools/mut.py`
- `checks/tools/slice.py`
- `checks/tools/test-checks.sh`
- `docs/00-audit.md`
- `docs/adr/0001-architecture.md`
- `docs/adr/0002-outils.md`
- `docs/adr/0003-gates-et-exceptions.md`

## Sortie complète de `make test-checks`

```text
== Étape 01
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   déclenchement manuel retiré
  PASS  mutant c2   détecté par C2   droits par défaut rendus au jeton
  PASS  mutant c3   détecté par C3   une action épinglée par tag
  PASS  mutant c4   détecté par C4   persistance du jeton réactivée
  PASS  mutant c5   détecté par C5   le job n'appelle plus make
  PASS  mutant c6   détecté par C6   artifact non publié en cas d'échec
  PASS  mutant c7   détecté par C7   durée maximale retirée
  PASS  mutant c8   détecté par C8   annulation de l'exécution précédente retirée
  PASS  mutant c9   détecté par C9   pipefail retiré : le tube masque l'échec
== Étape 02
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   image de base sans digest
  PASS  mutant c2   détecté par C2   exécution en root
  PASS  mutant c3   détecté par C3   contrôle de santé retiré
  PASS  mutant c4   détecté par C4   cache pip conservé dans l'image
  PASS  mutant c5   détecté par C5   la cible test ne lance plus les tests
  PASS  mutant c6   détecté par C6   la cible build ignore la variable IMAGE
  PASS  mutant c7   détecté par C7   le job build-test ne lance plus les tests
== Étape 03
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   règles par défaut désactivées
  PASS  mutant c2   détecté par C2   règle maison qui ne reconnaît plus le format du lab
  PASS  mutant c3   détecté par C3   scan du répertoire courant au lieu de l'historique
  PASS  mutant c4   détecté par C4   rapport écrit ailleurs qu'à l'emplacement imposé
  PASS  mutant c5   détecté par C5   la cible du hook ne regarde plus les fichiers indexés
  PASS  mutant c6   détecté par C6   le hook appelle le scan d'historique
  PASS  mutant c7   détecté par C7   historique tronqué dans le job
  PASS  mutant c8   détecté par C8   secrets affichés en clair
== Étape 04
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   jeux de règles communautaires retirés
  PASS  mutant c2   détecté par C2   règle maison sur les secrets de configuration retirée
  PASS  mutant c3   détecté par C3   règle maison sur le mode debug retirée
  PASS  mutant c4   détecté par C4   le SAST bloque sur toutes les sévérités
  PASS  mutant c5   détecté par C5   la cible sca ne bloque plus
  PASS  mutant c6   détecté par C6   seuil écrit en dur au lieu d'être piloté par la variable
  PASS  mutant c7   détecté par C7   rapport SAST écrit ailleurs qu'à l'emplacement imposé
  PASS  mutant c8   détecté par C8   l'envoi du rapport peut faire échouer un job
== Étape 05
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   outil d'installation laissé dans l'image
  PASS  mutant c2   détecté par C2   le scan d'image ne bloque plus
  PASS  mutant c3   détecté par C3   socket Docker monté dans le scanner
  PASS  mutant c4   détecté par C4   configuration de l'image non analysée
  PASS  mutant c5   détecté par C5   rapport d'image écrit ailleurs qu'à l'emplacement imposé
  PASS  mutant c6   détecté par C6   le job image ne scanne plus
== Étape 06
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   la cible tf-fmt ne vérifie plus le format
  PASS  mutant c2   détecté par C2   la cible tf-validate ne valide plus
  PASS  mutant c3   détecté par C3   le plan exige des identifiants AWS
  PASS  mutant c4   détecté par C4   le rôle applicatif n'est plus créé
  PASS  mutant c5   détecté par C5   une ressource payante est ajoutée
  PASS  mutant c6   détecté par C6   fichier de verrouillage des providers absent
  PASS  mutant c7   détecté par C7   verrou d'état désactivé
  PASS  mutant c8   détecté par C8   le job de plan des PR peut demander un jeton cloud
== Étape 07
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   Trivy config ne bloque plus
  PASS  mutant c2   détecté par C2   Checkov ne bloque plus
  PASS  mutant c3   détecté par C3   policy trop stricte : elle refuse un plan conforme
  PASS  mutant c4   détecté par C4   policy S3 neutralisée
  PASS  mutant c5   détecté par C5   policy réseau neutralisée
  PASS  mutant c6   détecté par C6   un tag obligatoire n'est plus exigé
  PASS  mutant c7   détecté par C7   un type de ressource payante n'est plus interdit
  PASS  mutant c8   détecté par C8   tests unitaires des policies supprimés
  PASS  mutant c9   détecté par C9   le résultat des policies n'est plus pris en compte
  PASS  mutant c10  détecté par C10  le workflow de PR ne lance plus les policies
== Étape 08
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   le job exceptions ne vérifie plus rien
  PASS  mutant c2   détecté par C2   la cible exceptions accepte tout
  PASS  mutant c3   détecté par C3   seuil par défaut abaissé
  PASS  mutant c4   détecté par C4   le verdict peut être sauté
  PASS  mutant c5   détecté par C5   un contrôle n'est plus un prérequis du verdict
  PASS  mutant c6   détecté par C6   le verdict ne reçoit plus le résultat des jobs
  PASS  mutant c7   détecté par C7   le scan global ne renvoie plus d'échec
  PASS  mutant c8   détecté par C8   droit de commenter la PR retiré
  PASS  mutant c9   détecté par C9   titre de la PR inséré dans un script
== Étape 09
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   ruleset désactivé
  PASS  mutant c2   détecté par C2   un rôle peut contourner le ruleset
  PASS  mutant c3   détecté par C3   réécriture d'historique autorisée
  PASS  mutant c4   détecté par C4   pull request non obligatoire
  PASS  mutant c5   détecté par C5   un statut n'est plus requis
  PASS  mutant c6   détecté par C6   push protection non activée
  PASS  mutant c7   détecté par C7   le script recrée le ruleset à chaque lancement
== Étape 10
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   fournisseur d'identité pointant ailleurs que GitHub Actions
  PASS  mutant c2   détecté par C2   comparaison du sujet par motif
  PASS  mutant c2b  détecté par C2   sujet avec joker
  PASS  mutant c3   détecté par C3   condition sur l'audience retirée
  PASS  mutant c4   détecté par C4   bucket d'état sans versioning
  PASS  mutant c5   détecté par C5   alerte de budget supprimée
  PASS  mutant c6   détecté par C6   clé d'accès statique dans le workflow de déploiement
  PASS  mutant c7   détecté par C7   apply hors de tout environnement, donc sans approbation
  PASS  mutant c8   détecté par C8   déploiement déclenchable par une pull request
  PASS  mutant c9   détecté par C9   toutes les actions accordées au rôle de déploiement
  PASS  mutant c10  détecté par C10  apply sans confirmation explicite
== Étape 11
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   inventaire produit dans un autre format
  PASS  mutant c2   détecté par C2   le scan de l'inventaire ne bloque plus
  PASS  mutant c3   détecté par C3   image Prowler sans digest
  PASS  mutant c4   détecté par C4   inventaire aussi produit sur les pull requests
== Progression : étapes 1 à N résolues
  PASS  N=1 : check-etape-01 passe
  PASS  N=1 : check-etape-02 échoue
  PASS  N=2 : check-etape-02 passe
  PASS  N=2 : check-etape-03 échoue
  PASS  N=3 : check-etape-03 passe
  PASS  N=3 : check-etape-04 échoue
  PASS  N=4 : check-etape-04 passe
  PASS  N=4 : check-etape-05 échoue
  PASS  N=5 : check-etape-05 passe
  PASS  N=5 : check-etape-06 échoue
  PASS  N=6 : check-etape-06 passe
  PASS  N=6 : check-etape-07 échoue
  PASS  N=7 : check-etape-07 passe
  PASS  N=7 : check-etape-08 échoue
  PASS  N=8 : check-etape-08 passe
  PASS  N=8 : check-etape-09 échoue
  PASS  N=9 : check-etape-09 passe
  PASS  N=9 : check-etape-10 échoue
  PASS  N=10 : check-etape-10 passe
  PASS  N=10 : check-etape-11 échoue
== Cohérence page / contrôle / mutant
  PASS  86 contraintes, 0 sans contrôle ou sans mutant
== Fuite du corrigé sur la branche d'exercices
  donnée d'entrée : 117 ; faute injectée : 12 ; nécessaire au check : 110 ; énoncé / contrat : 203
  PASS  494 lignes et 792 littéraux cherchés dans 75 fichiers, 0 fuite(s) (détail : reports/fuites.md)
== Outillage de mainteneur absent de la branche d'exercices
  PASS  aucun fichier ni cible de mainteneur
test-checks : TOUT EST VERT
```

Durée : 15 minutes, caches chauds.

## Recherche de fuite : fragments du corrigé présents sur la branche d'exercices

494 lignes et 792 littéraux du corrigé cherchés dans 75 fichiers.

| Classe | Occurrences |
|---|---|
| donnée d'entrée | 117 |
| faute injectée | 12 |
| nécessaire au check | 110 |
| énoncé / contrat | 203 |

### nécessaire au check

| Fragment | Vient de | Justification | Emplacements |
|---|---|---|---|
| `--all-namespaces` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/lib.sh:150 |
| `--entrypoint` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-02.sh:18, checks/etape-02.sh:20, checks/etape-10.sh:36 |
| `--entrypoint sh` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-02.sh:20, checks/etape-10.sh:36 |
| `--policy policies` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/lib.sh:150 |
| `-e AWS_ACCESS_KEY_ID` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-e AWS_ACCESS_KEY_ID=offline` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-e AWS_SECRET_ACCESS_KEY` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-e AWS_SECRET_ACCESS_KEY=offline` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-e CHECKPOINT_DISABLE=1` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-e TF_DATA_DIR=/tmp/tfdata` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-e TF_IN_AUTOMATION=1` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `-input=false` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:35 |
| `-r terraform` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:35 |
| `AWS_ACCESS_KEY_ID` | Makefile | Nom standard d'une variable d'identifiants AWS : retirée de l'environnement par sécurité, et cherchée pour interdire toute clé statique (étape 10, contrainte 6). | checks/etape-10.sh:10, checks/etape-10.sh:36, checks/lib.sh:15 |
| `AWS_ACCESS_KEY_ID=offline` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `aws_budgets_budget` | terraform/bootstrap/budget.tf | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape10.rego:25 |
| `aws_db_instance` | policies/cout.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:24 |
| `aws_eks_cluster` | policies/cout.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:24 |
| `aws_iam_openid_connect_provider` | terraform/bootstrap/oidc.tf | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape10.rego:8 |
| `aws_iam_role` | terraform/modules/iam/main.tf | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:15 |
| `aws_instance` | policies/cout.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:24 |
| `aws_nat_gateway` | policies/policies_test.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:24 |
| `aws_s3_bucket` | policies/policies_test.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:14, checks/policy/etape06.rego:15, checks/policy/etape10.rego:20 |
| `aws_s3_bucket_public_access_block` | policies/policies_test.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:15, checks/policy/etape10.rego:20 |
| `aws_s3_bucket_server_side_encryption_configuration` | terraform/modules/s3/main.tf | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape10.rego:20 |
| `aws_s3_bucket_versioning` | terraform/modules/s3/main.tf | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape10.rego:20 |
| `AWS_SECRET_ACCESS_KEY` | Makefile | Nom standard d'une variable d'identifiants AWS : retirée de l'environnement par sécurité, et cherchée pour interdire toute clé statique (étape 10, contrainte 6). | checks/etape-10.sh:10, checks/etape-10.sh:36, checks/lib.sh:15 |
| `AWS_SECRET_ACCESS_KEY=offline` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `aws_security_group` | policies/policies_test.rego | Type de ressource Terraform nommé en clair par l'énoncé (VPC, bucket, rôle, ressources payantes, budget) : le contrôle le cherche dans le plan. | checks/policy/etape06.rego:14 |
| `AWS_SESSION_TOKEN` | Makefile | Nom standard d'une variable d'identifiants AWS : retirée de l'environnement par sécurité, et cherchée pour interdire toute clé statique (étape 10, contrainte 6). | checks/lib.sh:15 |
| `bypass_actors` | .github/rulesets/main.json | Champ public de l'API des rulesets GitHub : sans lui, aucun contrôle statique du ruleset n'est possible (étape 9). Divulgue la forme du fichier attendu. | checks/policy/etape09.rego:17, checks/policy/etape09.rego:18 |
| `cancel-in-progress` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape01.rego:77 |
| `CHECKPOINT_DISABLE=1` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `client_id_list` | terraform/bootstrap/oidc.tf | Structure publique d'un plan Terraform en JSON, visible aussi dans les plans de référence fournis. | checks/policy/etape10.rego:16 |
| `continue-on-error` | .github/workflows/pr-security.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape04.rego:24 |
| `Gachtout/Lab-CI-CD` | terraform/bootstrap/terraform.tfvars.example | Nom du dépôt, présent dans les liens. | README.md:4, README.md:67, README.md:90, README.md:91, README.md:95, docs/etapes/01-pipeline-minimal.md:115 … (+10) |
| `Gachtout/Lab-CI-CD` | extrait de code d'une page | Nom du dépôt, présent dans les liens. | README.md:90, README.md:91 |
| `github.repository` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape08.rego:40 |
| `https://token.actions.githubusercontent.com` | terraform/bootstrap/oidc.tf | Valeur publique de la fédération d'identité GitHub vers AWS : indispensable pour vérifier les contraintes 1 à 3 de l'étape 10. | checks/policy/etape10.rego:11 |
| `input.resource_changes` | policies/lib.rego | Structure publique d'un plan Terraform en JSON, visible aussi dans les plans de référence fournis. | checks/policy/etape06.rego:8, checks/policy/etape06.rego:28, checks/policy/etape10.rego:6 |
| `non_fast_forward` | .github/rulesets/main.json | Champ public de l'API des rulesets GitHub : sans lui, aucun contrôle statique du ruleset n'est possible (étape 9). Divulgue la forme du fichier attendu. | checks/policy/etape09.rego:22 |
| `persist-credentials` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape01.rego:47 |
| `pull-requests` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape08.rego:29, checks/policy/etape08.rego:35 |
| `pull_request` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape01.rego:9, checks/policy/etape01.rego:15, checks/policy/etape06_workflow.rego:9, checks/policy/etape06_workflow.rego:11, checks/policy/etape06_workflow.rego:12, checks/policy/etape08.rego:45 … (+4) |
| `rc.change.actions` | policies/lib.rego | Structure publique d'un plan Terraform en JSON, visible aussi dans les plans de référence fournis. | checks/policy/etape06.rego:10, checks/policy/etape06.rego:30, checks/policy/etape10.rego:6 |
| `refs/heads/main` | .github/workflows/destroy.yml | Champ public de l'API des rulesets GitHub : sans lui, aucun contrôle statique du ruleset n'est possible (étape 9). Divulgue la forme du fichier attendu. | checks/policy/etape09.rego:14 |
| `required_status_checks` | .github/rulesets/main.json | Champ public de l'API des rulesets GitHub : sans lui, aucun contrôle statique du ruleset n'est possible (étape 9). Divulgue la forme du fichier attendu. | checks/policy/etape09.rego:33, checks/policy/etape09.rego:34, checks/policy/etape09.rego:40, checks/policy/etape09.rego:43, checks/policy/etape09.rego:45, checks/policy/etape09.rego:46 |
| `resource_changes` | policies/policies_test.rego | Structure publique d'un plan Terraform en JSON, visible aussi dans les plans de référence fournis. | checks/policy/etape06.rego:8, checks/policy/etape06.rego:28, checks/policy/etape10.rego:6 |
| `retention-days` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape01.rego:63, checks/policy/etape11.rego:19 |
| `security-events` | .github/workflows/pr-security.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape04.rego:32 |
| `strict_required_status_checks_policy` | .github/rulesets/main.json | Champ public de l'API des rulesets GitHub : sans lui, aucun contrôle statique du ruleset n'est possible (étape 9). Divulgue la forme du fichier attendu. | checks/policy/etape09.rego:46 |
| `sts.amazonaws.com` | terraform/bootstrap/oidc.tf | Valeur publique de la fédération d'identité GitHub vers AWS : indispensable pour vérifier les contraintes 1 à 3 de l'étape 10. | checks/policy/etape10.rego:16 |
| `TF_DATA_DIR=/tmp/tfdata` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `TF_IN_AUTOMATION=1` | Makefile | Option de la commande que la vérification lance elle-même (Conftest, Docker, Terraform hors ligne). La planification hors ligne du bootstrap n'apparaît que dans la vérification de l'étape 10, postérieure à l'étape 6 où tu dois la trouver. | checks/etape-10.sh:36 |
| `timeout-minutes` | .github/workflows/terraform-plan.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape01.rego:72 |
| `upload-sarif` | .github/workflows/pr-security.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape04.rego:23, checks/policy/etape04.rego:31 |
| `use_lockfile` | terraform/envs/dev/versions.tf | Nom d'option que le contrôle cherche par motif, faute de pouvoir exécuter le backend S3 (étape 6) ou le script GitHub (étape 9). | checks/etape-06.sh:11 |
| `workflow_dispatch` | .github/workflows/deploy.yml | Clé ou valeur publique de GitHub Actions : le contrôle de structure doit la lire dans ton workflow pour vérifier la contrainte correspondante. | checks/policy/etape01.rego:9, checks/policy/etape10_destroy.rego:9 |
| `~DEFAULT_BRANCH` | .github/rulesets/main.json | Champ public de l'API des rulesets GitHub : sans lui, aucun contrôle statique du ruleset n'est possible (étape 9). Divulgue la forme du fichier attendu. | checks/policy/etape09.rego:14 |

### énoncé / contrat

| Fragment | Vient de | Justification | Emplacements |
|---|---|---|---|
| `$(CONFTEST_IMAGE` | Makefile | nom ou valeur imposé par un énoncé | checks/checks.mk:6 |
| `-e TF_PLUGIN_CACHE_DIR=/cache/terraform/plugins` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-10.sh:36 |
| `.dockerignore` | app/.dockerignore | nom ou valeur imposé par un énoncé | docs/etapes/02-build-test-docker.md:28, docs/etapes/02-build-test-docker.md:74 |
| `.github/rulesets/main.json` | scripts/setup-github.sh | nom ou valeur imposé par un énoncé | checks/etape-09.sh:5, checks/etape-09.sh:13, docs/etapes/09-branch-protection.md:49, docs/etapes/09-branch-protection.md:68 |
| `.github/workflows/deploy.yml` | .github/workflows/deploy.yml | nom ou valeur imposé par un énoncé | docs/etapes/10-oidc-deploy.md:95 |
| `.gitleaks.toml` | .gitleaks.toml | nom ou valeur imposé par un énoncé | checks/etape-03.sh:5, docs/etapes/03-secrets.md:29, docs/etapes/03-secrets.md:51, docs/etapes/03-secrets.md:111 |
| `.pre-commit-config.yaml` | .pre-commit-config.yaml | nom ou valeur imposé par un énoncé | checks/etape-03.sh:6, docs/etapes/03-secrets.md:31 |
| `.trivyignore.yaml` | .trivyignore.yaml | nom ou valeur imposé par un énoncé | docs/etapes/08-quality-gates.md:50, docs/etapes/08-quality-gates.md:112, docs/reference/mapping-wiz.md:19, scripts/check-exceptions.sh:4, scripts/check-exceptions.sh:30, scripts/check-exceptions.sh:31 … (+5) |
| `budget_email` | terraform/bootstrap/variables.tf | nom ou valeur imposé par un énoncé | checks/etape-10.sh:35, docs/etapes/10-oidc-deploy.md:94 |
| `deploy.yml` | .github/workflows/deploy.yml | nom ou valeur imposé par un énoncé | checks/etape-10.sh:8, docs/etapes/10-oidc-deploy.md:72, docs/etapes/10-oidc-deploy.md:95 |
| `destroy.yml` | .github/workflows/destroy.yml | nom ou valeur imposé par un énoncé | checks/etape-10.sh:9, docs/etapes/10-oidc-deploy.md:72, docs/etapes/10-oidc-deploy.md:95 |
| `DOCKER_BUILD` | Makefile | nom ou valeur imposé par un énoncé | docs/etapes/02-build-test-docker.md:21, docs/etapes/02-build-test-docker.md:81 |
| `github_repository` | terraform/bootstrap/variables.tf | nom ou valeur imposé par un énoncé | checks/etape-10.sh:35, docs/etapes/10-oidc-deploy.md:94 |
| `lab-fake-token` | .gitleaks.toml | nom ou valeur imposé par un énoncé | checks/policy/etape03.rego:7, docs/etapes/03-secrets.md:37, docs/etapes/03-secrets.md:53 |
| `make aws-apply` | .github/workflows/deploy.yml | nom ou valeur imposé par un énoncé | docs/etapes/10-oidc-deploy.md:73, docs/etapes/10-oidc-deploy.md:86 |
| `make aws-destroy` | .github/workflows/destroy.yml | nom ou valeur imposé par un énoncé | docs/etapes/10-oidc-deploy.md:73, docs/etapes/10-oidc-deploy.md:86 |
| `make aws-plan` | .github/workflows/deploy.yml | nom ou valeur imposé par un énoncé | docs/etapes/10-oidc-deploy.md:73 |
| `make iac-checkov` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | docs/etapes/07-iac-policies.md:36, docs/etapes/07-iac-policies.md:44 |
| `make iac-trivy` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | docs/etapes/07-iac-policies.md:36, docs/etapes/07-iac-policies.md:43 |
| `make image-scan` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/policy/etape05.rego:11, docs/etapes/05-image.md:27, docs/etapes/05-image.md:34, docs/etapes/05-image.md:36, docs/etapes/05-image.md:38, docs/etapes/05-image.md:47 … (+1) |
| `make lint-workflows` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/policy/etape01.rego:52, docs/etapes/01-pipeline-minimal.md:34, docs/etapes/01-pipeline-minimal.md:43, docs/etapes/01-pipeline-minimal.md:47, docs/etapes/01-pipeline-minimal.md:93 |
| `make secrets` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-03.sh:22, checks/policy/etape03_precommit.rego:8, checks/policy/etape03_workflow.rego:9, checks/policy/etape03_workflow.rego:10, docs/etapes/03-secrets.md:30, docs/etapes/03-secrets.md:36 … (+7) |
| `make secrets-staged` | .pre-commit-config.yaml | nom ou valeur imposé par un énoncé | checks/policy/etape03_precommit.rego:8, docs/etapes/03-secrets.md:30, docs/etapes/03-secrets.md:40, docs/etapes/03-secrets.md:41 |
| `make summary` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | docs/etapes/08-quality-gates.md:27, docs/etapes/08-quality-gates.md:38 |
| `make tf-validate` | .github/workflows/terraform-plan.yml | nom ou valeur imposé par un énoncé | checks/policy/etape06_workflow.rego:22, docs/etapes/06-terraform.md:40, docs/etapes/06-terraform.md:46, docs/etapes/06-terraform.md:52, docs/etapes/06-terraform.md:100 |
| `pr-security.yml` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-01.sh:4, checks/etape-02.sh:7, checks/etape-03.sh:7, checks/etape-04.sh:5, checks/etape-05.sh:8, checks/etape-07.sh:6 … (+11) |
| `PROWLER_IMAGE` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-11.sh:14, docs/etapes/11-prowler-sbom.md:34, docs/etapes/11-prowler-sbom.md:53 |
| `reports/actionlint.txt` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-01.sh:17, docs/etapes/01-pipeline-minimal.md:47, docs/etapes/01-pipeline-minimal.md:58 |
| `reports/gitleaks.sarif` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-03.sh:12, docs/etapes/03-secrets.md:39, docs/etapes/03-secrets.md:54 |
| `reports/sbom.cdx.json` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-11.sh:20, checks/etape-11.sh:23, docs/etapes/11-prowler-sbom.md:39, docs/etapes/11-prowler-sbom.md:51 |
| `reports/semgrep.sarif` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-04.sh:10, docs/etapes/04-sast-sca.md:44, docs/etapes/04-sast-sca.md:57 |
| `reports/tfplan.txt` | .github/workflows/terraform-plan.yml | nom ou valeur imposé par un énoncé | docs/etapes/06-terraform.md:62 |
| `reports/trivy-image.sarif` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-05.sh:14, docs/etapes/05-image.md:37, docs/etapes/05-image.md:48 |
| `reports/trivy-sca.sarif` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/etape-04.sh:26, docs/etapes/04-sast-sca.md:44, docs/etapes/04-sast-sca.md:57 |
| `scripts/pr-comment.sh` | .github/workflows/terraform-plan.yml | nom ou valeur imposé par un énoncé | docs/etapes/08-quality-gates.md:20, docs/etapes/08-quality-gates.md:82 |
| `scripts/summary.py` | Makefile | nom ou valeur imposé par un énoncé | docs/etapes/08-quality-gates.md:19, docs/reference/mapping-wiz.md:20 |
| `security-gate` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/policy/etape08.rego:1, checks/policy/etape08.rego:8, checks/policy/etape08.rego:14, checks/policy/etape08.rego:16, checks/policy/etape08.rego:25, checks/policy/etape08.rego:28 … (+13) |
| `SEMGREP_SEVERITY` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-08.sh:8, checks/etape-08.sh:11, checks/etape-08.sh:12, docs/etapes/04-sast-sca.md:41, docs/etapes/04-sast-sca.md:55 |
| `setup-github.sh` | scripts/setup-github.sh | nom ou valeur imposé par un énoncé | checks/etape-09.sh:6, docs/etapes/09-branch-protection.md:50, docs/etapes/09-branch-protection.md:69 |
| `terraform-plan` | .github/workflows/terraform-plan.yml | nom ou valeur imposé par un énoncé | checks/etape-06.sh:6, checks/etape-07.sh:7, checks/policy/etape06.rego:1, checks/policy/etape07_plan.rego:7, docs/etapes/06-terraform.md:41, docs/etapes/06-terraform.md:52 … (+3) |
| `terraform-plan.yml` | .github/workflows/terraform-plan.yml | nom ou valeur imposé par un énoncé | checks/etape-06.sh:6, checks/etape-07.sh:7, docs/etapes/06-terraform.md:41, docs/etapes/06-terraform.md:63, docs/etapes/07-iac-policies.md:38 |
| `terraform/bootstrap` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-10.sh:5, docs/etapes/10-oidc-deploy.md:71, docs/etapes/10-oidc-deploy.md:94 |
| `terraform/envs/dev` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-06.sh:4, checks/etape-07.sh:4, checks/etape-08.sh:18, checks/etape-08.sh:20, docs/etapes/06-terraform.md:39, docs/etapes/06-terraform.md:50 … (+1) |
| `TF_PLUGIN_CACHE_DIR=/cache/terraform/plugins` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-10.sh:36 |
| `TF_STATE_BUCKET` | .github/workflows/deploy.yml | nom ou valeur imposé par un énoncé | checks/etape-10.sh:26, docs/etapes/10-oidc-deploy.md:98 |
| `TRIVY_SEVERITY` | Makefile | nom ou valeur imposé par un énoncé | checks/etape-04.sh:30, checks/etape-08.sh:8, checks/etape-08.sh:9, checks/etape-08.sh:10, docs/etapes/04-sast-sca.md:43, docs/etapes/04-sast-sca.md:55 … (+1) |
| `workflow-lint` | .github/workflows/pr-security.yml | nom ou valeur imposé par un énoncé | checks/policy/etape01.rego:31, checks/policy/etape01.rego:32, checks/policy/etape01.rego:51, checks/policy/etape01.rego:52, checks/policy/etape01.rego:55, checks/policy/etape01.rego:56 … (+6) |

### donnée d'entrée

| Fragment | Vient de | Justification | Emplacements |
|---|---|---|---|
| `10.20.0.0/16` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:17, checks/fixtures/plan-bucket-public.json:105, checks/fixtures/plan-entree-ouverte.json:17, checks/fixtures/plan-ressource-payante.json:17, checks/fixtures/plan-ressource-payante.json:105, checks/fixtures/plan-sain.json:17 … (+3) |
| `aws_nat_gateway` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-ressource-payante.json:121, checks/fixtures/plan-ressource-payante.json:123 |
| `aws_s3_bucket` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:29, checks/fixtures/plan-bucket-public.json:31, checks/fixtures/plan-bucket-public.json:52, checks/fixtures/plan-bucket-public.json:54, checks/fixtures/plan-entree-ouverte.json:29, checks/fixtures/plan-entree-ouverte.json:31 … (+14) |
| `aws_s3_bucket_public_access_block` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:52, checks/fixtures/plan-bucket-public.json:54, checks/fixtures/plan-entree-ouverte.json:52, checks/fixtures/plan-entree-ouverte.json:54, checks/fixtures/plan-ressource-payante.json:52, checks/fixtures/plan-ressource-payante.json:54 … (+4) |
| `aws_security_group` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:71, checks/fixtures/plan-bucket-public.json:73, checks/fixtures/plan-entree-ouverte.json:71, checks/fixtures/plan-entree-ouverte.json:73, checks/fixtures/plan-ressource-payante.json:71, checks/fixtures/plan-ressource-payante.json:73 … (+4) |
| `aws_vpc_security_group_ingress_rule` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:94, checks/fixtures/plan-bucket-public.json:96, checks/fixtures/plan-entree-ouverte.json:94, checks/fixtures/plan-entree-ouverte.json:96, checks/fixtures/plan-ressource-payante.json:94, checks/fixtures/plan-ressource-payante.json:96 … (+4) |
| `block_public_acls` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:63, checks/fixtures/plan-entree-ouverte.json:63, checks/fixtures/plan-ressource-payante.json:63, checks/fixtures/plan-sain.json:63, checks/fixtures/plan-tag-manquant.json:61 |
| `block_public_policy` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:64, checks/fixtures/plan-entree-ouverte.json:64, checks/fixtures/plan-ressource-payante.json:64, checks/fixtures/plan-sain.json:64, checks/fixtures/plan-tag-manquant.json:62 |
| `bucket_prefix` | terraform/modules/s3/main.tf | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:40, checks/fixtures/plan-entree-ouverte.json:40, checks/fixtures/plan-ressource-payante.json:40, checks/fixtures/plan-sain.json:40, checks/fixtures/plan-tag-manquant.json:39 |
| `hashicorp/aws` | terraform/envs/dev/versions.tf | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:10, checks/fixtures/plan-bucket-public.json:33, checks/fixtures/plan-bucket-public.json:56, checks/fixtures/plan-bucket-public.json:75, checks/fixtures/plan-bucket-public.json:98, checks/fixtures/plan-entree-ouverte.json:10 … (+20) |
| `ignore_public_acls` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:65, checks/fixtures/plan-entree-ouverte.json:65, checks/fixtures/plan-ressource-payante.json:65, checks/fixtures/plan-sain.json:65, checks/fixtures/plan-tag-manquant.json:63 |
| `resource_changes` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:4, checks/fixtures/plan-entree-ouverte.json:4, checks/fixtures/plan-ressource-payante.json:4, checks/fixtures/plan-sain.json:4, checks/fixtures/plan-tag-manquant.json:4 |
| `restrict_public_buckets` | policies/policies_test.rego | plan Terraform de référence fourni à l'étape 7 | checks/fixtures/plan-bucket-public.json:66, checks/fixtures/plan-entree-ouverte.json:66, checks/fixtures/plan-ressource-payante.json:66, checks/fixtures/plan-sain.json:66, checks/fixtures/plan-tag-manquant.json:64 |

### faute injectée

| Fragment | Vient de | Justification | Emplacements |
|---|---|---|---|
| `-r requirements.txt` | app/Dockerfile | version fautive, jamais la version correcte | checks/faults/etape-05/image-vulnerable.faute:6 |
| `0.0.0.0:8000` | app/Dockerfile | version fautive, jamais la version correcte | checks/faults/etape-05/image-vulnerable.faute:8 |
| `aws_s3_bucket` | policies/policies_test.rego | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:2, checks/faults/etape-07/bucket-public.faute:6, checks/faults/etape-07/bucket-public.faute:7 |
| `aws_s3_bucket_public_access_block` | policies/policies_test.rego | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:6 |
| `block_public_acls` | policies/policies_test.rego | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:9 |
| `block_public_policy` | policies/policies_test.rego | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:10 |
| `bucket_prefix` | terraform/modules/s3/main.tf | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:3 |
| `ignore_public_acls` | policies/policies_test.rego | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:11 |
| `pull_request` | .github/workflows/terraform-plan.yml | version fautive, jamais la version correcte | checks/faults/etape-01/workflow-faux.faute:8 |
| `restrict_public_buckets` | policies/policies_test.rego | version fautive, jamais la version correcte | checks/faults/etape-07/bucket-public.faute:12 |

## Correspondance contrainte, contrôle, mutant

| Étape | Contrainte | Énoncé | Contrôle | Mutant |
|---|---|---|---|---|
| 01 | C1 | Le workflow se déclenche sur les pull requests visant `main`, sur les … | structure (Rego) | `c1` déclenchement manuel retiré |
| 01 | C2 | Le jeton du workflow n'a aucun droit par défaut. Chaque job déclare le… | structure (Rego) | `c2` droits par défaut rendus au jeton |
| 01 | C3 | Toute action tierce est épinglée par SHA de commit complet. | structure (Rego) | `c3` une action épinglée par tag |
| 01 | C4 | Le jeton ne reste pas dans la configuration git du runner après la réc… | structure (Rego) | `c4` persistance du jeton réactivée |
| 01 | C5 | Le job n'installe aucun outil : il appelle `make lint-workflows`. | structure (Rego) | `c5` le job n'appelle plus make |
| 01 | C6 | Le rapport est publié en artifact même si le lint échoue, et conservé … | structure (Rego) | `c6` artifact non publié en cas d'échec |
| 01 | C7 | Chaque job a une durée maximale explicite. | structure (Rego) | `c7` durée maximale retirée |
| 01 | C8 | Un nouveau push sur la même référence annule l'exécution précédente. | structure (Rego) | `c8` annulation de l'exécution précédente retirée |
| 01 | C9 | `make lint-workflows` écrit sa sortie dans `reports/actionlint.txt` et… | contrôle scripté + comportement : doit réussir + comportement : doit échouer | `c9` pipefail retiré : le tube masque l'échec |
| 02 | C1 | L'image de base est épinglée par digest. | structure (Rego) | `c1` image de base sans digest |
| 02 | C2 | Le conteneur ne s'exécute pas en root : un utilisateur sans privilège … | structure (Rego) + contrôle scripté | `c2` exécution en root |
| 02 | C3 | L'image déclare un contrôle de santé. | structure (Rego) | `c3` contrôle de santé retiré |
| 02 | C4 | L'installation des dépendances ne laisse pas le cache de `pip` dans l'… | contrôle scripté | `c4` cache pip conservé dans l'image |
| 02 | C5 | `make test` lance les tests unitaires dans l'image Python de la plombe… | comportement : doit réussir + comportement : doit échouer | `c5` la cible test ne lance plus les tests |
| 02 | C6 | `make build` construit l'image dont le nom est donné par la variable `… | comportement : doit réussir + contrôle scripté | `c6` la cible build ignore la variable IMAGE |
| 02 | C7 | Le job `build-test` appelle `make test` puis `make build`. | structure (Rego) | `c7` le job build-test ne lance plus les tests |
| 03 | C1 | `make secrets` réussit sur un historique sain et échoue dès qu'un secr… | comportement : doit réussir + comportement : doit échouer | `c1` règles par défaut désactivées |
| 03 | C2 | Une règle maison, d'identifiant `lab-fake-token`, détecte le format in… | structure (Rego) + comportement : doit échouer | `c2` règle maison qui ne reconnaît plus le format du lab |
| 03 | C3 | `make secrets` analyse tout l'historique git : un secret commité puis … | comportement : doit échouer | `c3` scan du répertoire courant au lieu de l'historique |
| 03 | C4 | `make secrets` produit un rapport SARIF dans `reports/gitleaks.sarif`. | présence du rapport | `c4` rapport écrit ailleurs qu'à l'emplacement imposé |
| 03 | C5 | `make secrets-staged` n'analyse que les fichiers indexés, pas encore c… | comportement : doit réussir + comportement : doit échouer | `c5` la cible du hook ne regarde plus les fichiers indexés |
| 03 | C6 | Un hook pre-commit appelle `make secrets-staged`. | structure (Rego) | `c6` le hook appelle le scan d'historique |
| 03 | C7 | Le job `secrets` récupère tout l'historique avant d'appeler `make secr… | structure (Rego) | `c7` historique tronqué dans le job |
| 03 | C8 | La valeur d'un secret détecté n'apparaît jamais en clair dans la sorti… | contrôle scripté | `c8` secrets affichés en clair |
| 04 | C1 | `make sast` réussit sur le code fourni et échoue sur une injection SQL… | comportement : doit réussir + comportement : doit échouer | `c1` jeux de règles communautaires retirés |
| 04 | C2 | Une règle maison bloque un secret de configuration écrit en dur (une c… | comportement : doit échouer | `c2` règle maison sur les secrets de configuration retirée |
| 04 | C3 | Une règle maison bloque l'activation en dur du mode debug de Flask. | comportement : doit échouer | `c3` règle maison sur le mode debug retirée |
| 04 | C4 | Seuls les constats de sévérité `ERROR` font échouer `make sast` ; le s… | comportement : doit réussir | `c4` le SAST bloque sur toutes les sévérités |
| 04 | C5 | `make sca` réussit sur les dépendances fournies et échoue sur des dépe… | comportement : doit réussir + comportement : doit échouer | `c5` la cible sca ne bloque plus |
| 04 | C6 | Le seuil de `make sca` est piloté par la variable `TRIVY_SEVERITY`, qu… | comportement : doit réussir | `c6` seuil écrit en dur au lieu d'être piloté par la variable |
| 04 | C7 | Les rapports SARIF sont écrits dans `reports/semgrep.sarif` et `report… | présence du rapport | `c7` rapport SAST écrit ailleurs qu'à l'emplacement imposé |
| 04 | C8 | Les jobs `sast` et `sca` appellent leur cible. Tout envoi de rapport v… | structure (Rego) | `c8` l'envoi du rapport peut faire échouer un job |
| 05 | C1 | `make build image-scan` réussit sur ton image : aucune vulnérabilité `… | comportement : doit réussir | `c1` outil d'installation laissé dans l'image |
| 05 | C2 | `make image-scan` échoue sur une image construite à partir d'une base … | comportement : doit échouer + contrôle scripté | `c2` le scan d'image ne bloque plus |
| 05 | C3 | Le scanner n'a pas accès au socket Docker. | lecture du fichier | `c3` socket Docker monté dans le scanner |
| 05 | C4 | `make image-scan` échoue sur une image qui s'exécute en root : la conf… | comportement : doit échouer + contrôle scripté | `c4` configuration de l'image non analysée |
| 05 | C5 | Le rapport SARIF est écrit dans `reports/trivy-image.sarif`. | présence du rapport | `c5` rapport d'image écrit ailleurs qu'à l'emplacement imposé |
| 05 | C6 | Le job `image` appelle `make build` puis `make image-scan`. | structure (Rego) | `c6` le job image ne scanne plus |
| 06 | C1 | `make tf-fmt` réussit sur ton code et échoue sur un fichier mal format… | comportement : doit réussir + comportement : doit échouer | `c1` la cible tf-fmt ne vérifie plus le format |
| 06 | C2 | `make tf-validate` réussit sur ton code et échoue sur une référence in… | comportement : doit réussir + comportement : doit échouer | `c2` la cible tf-validate ne valide plus |
| 06 | C3 | `make plan` fonctionne sans aucun identifiant AWS et exporte le plan d… | comportement : doit réussir + présence du rapport | `c3` le plan exige des identifiants AWS |
| 06 | C4 | Le plan crée au moins : un VPC, un sous-réseau, un security group, un … | structure (Rego) | `c4` le rôle applicatif n'est plus créé |
| 06 | C5 | Le plan ne crée aucune ressource payante : ni NAT Gateway, ni instance… | structure (Rego) | `c5` une ressource payante est ajoutée |
| 06 | C6 | Le fichier de verrouillage des providers est commité dans `terraform/e… | présence du fichier | `c6` fichier de verrouillage des providers absent |
| 06 | C7 | L'état distant est déclaré dans un backend S3, chiffré, avec le verrou… | lecture du fichier + contrôle scripté | `c7` verrou d'état désactivé |
| 06 | C8 | Le workflow `terraform-plan` se déclenche sur les pull requests, appel… | structure (Rego) | `c8` le job de plan des PR peut demander un jeton cloud |
| 07 | C1 | `make iac-trivy` réussit sur ton code et échoue sur un bucket exposabl… | comportement : doit réussir + comportement : doit échouer | `c1` Trivy config ne bloque plus |
| 07 | C2 | `make iac-checkov` réussit sur ton code et échoue sur le même bucket. | comportement : doit réussir + comportement : doit échouer | `c2` Checkov ne bloque plus |
| 07 | C3 | Tes policies acceptent un plan conforme : celui de `checks/fixtures/pl… | contrôle scripté + comportement : doit réussir | `c3` policy trop stricte : elle refuse un plan conforme |
| 07 | C4 | Tes policies refusent un bucket dont l'un des quatre blocages d'accès … | contrôle scripté | `c4` policy S3 neutralisée |
| 07 | C5 | Tes policies refusent une règle d'entrée ouverte à tout Internet, en I… | contrôle scripté | `c5` policy réseau neutralisée |
| 07 | C6 | Tes policies refusent une ressource taggable à laquelle il manque l'un… | contrôle scripté | `c6` un tag obligatoire n'est plus exigé |
| 07 | C7 | Tes policies refusent la création d'une ressource payante (au minimum … | contrôle scripté | `c7` un type de ressource payante n'est plus interdit |
| 07 | C8 | `make policy-test` exécute au moins quatre tests unitaires de policies… | contrôle scripté | `c8` tests unitaires des policies supprimés |
| 07 | C9 | `make policy` calcule le plan, applique les policies à ce plan, et éch… | comportement : doit échouer | `c9` le résultat des policies n'est plus pris en compte |
| 07 | C10 | Le job `iac` lance les deux scanners ; le workflow `terraform-plan` ap… | structure (Rego) | `c10` le workflow de PR ne lance plus les policies |
| 08 | C1 | `make exceptions` réussit sur ton dépôt, et un job `exceptions` l'appe… | structure (Rego) + comportement : doit réussir | `c1` le job exceptions ne vérifie plus rien |
| 08 | C2 | `make exceptions` échoue si une exception n'a pas de date d'expiration… | comportement : doit échouer | `c2` la cible exceptions accepte tout |
| 08 | C3 | Les seuils par défaut sont ceux du lab : vulnérabilités `HIGH` et `CRI… | contrôle scripté | `c3` seuil par défaut abaissé |
| 08 | C4 | Le job `security-gate` s'exécute même quand un contrôle a échoué. | structure (Rego) | `c4` le verdict peut être sauté |
| 08 | C5 | Le job `security-gate` dépend de tous les contrôles : `workflow-lint`,… | structure (Rego) | `c5` un contrôle n'est plus un prérequis du verdict |
| 08 | C6 | `make summary` reçoit le résultat des jobs par la variable d'environne… | comportement : doit réussir + comportement : doit échouer | `c6` le verdict ne reçoit plus le résultat des jobs |
| 08 | C7 | `make scan` lance tous les contrôles en local, ne s'arrête pas au prem… | comportement : doit réussir + comportement : doit échouer + contrôle scripté | `c7` le scan global ne renvoie plus d'échec |
| 08 | C8 | Seul le job `security-gate` peut écrire sur les pull requests, et il n… | structure (Rego) | `c8` droit de commenter la PR retiré |
| 08 | C9 | Aucune donnée non fiable de la pull request (titre, description, nom d… | structure (Rego) | `c9` titre de la PR inséré dans un script |
| 09 | C1 | Le ruleset est actif et vise la branche par défaut. | structure (Rego) | `c1` ruleset désactivé |
| 09 | C2 | Personne ne peut le contourner : la liste des acteurs exemptés est vid… | structure (Rego) | `c2` un rôle peut contourner le ruleset |
| 09 | C3 | La branche ne peut être ni supprimée, ni réécrite par un push forcé. | structure (Rego) | `c3` réécriture d'historique autorisée |
| 09 | C4 | Toute modification passe par une pull request. | structure (Rego) | `c4` pull request non obligatoire |
| 09 | C5 | La fusion exige les statuts `security-gate` et `plan`, sur une branche… | structure (Rego) | `c5` un statut n'est plus requis |
| 09 | C6 | Le script applique le fichier de ruleset versionné et active la protec… | présence du fichier + contrôle scripté + lecture du fichier | `c6` push protection non activée |
| 09 | C7 | Le script est rejouable : relancé, il met à jour le ruleset existant a… | lecture du fichier | `c7` le script recrée le ruleset à chaque lancement |
| 10 | C1 | Le bootstrap se planifie hors ligne et crée un fournisseur d'identité … | structure (Rego) + contrôle scripté | `c1` fournisseur d'identité pointant ailleurs que GitHub Actions |
| 10 | C2 | La politique de confiance des rôles compare le sujet du jeton en égali… | lecture du fichier | `c2` comparaison du sujet par motif ; `c2b` sujet avec joker |
| 10 | C3 | L'audience du jeton est vérifiée : seule celle d'AWS STS est acceptée. | lecture du fichier + structure (Rego) | `c3` condition sur l'audience retirée |
| 10 | C4 | Le bucket d'état est versionné, chiffré, et bloque tout accès public. | structure (Rego) | `c4` bucket d'état sans versioning |
| 10 | C5 | Une alerte de budget est créée. | structure (Rego) | `c5` alerte de budget supprimée |
| 10 | C6 | Aucune clé d'accès AWS statique n'apparaît dans un workflow : les jobs… | structure (Rego) + lecture du fichier | `c6` clé d'accès statique dans le workflow de déploiement |
| 10 | C7 | Tout job qui obtient des identifiants AWS s'exécute dans un environnem… | structure (Rego) | `c7` apply hors de tout environnement, donc sans approbation |
| 10 | C8 | Le déploiement ne peut pas être déclenché par une pull request ; en au… | structure (Rego) | `c8` déploiement déclenchable par une pull request |
| 10 | C9 | Aucune politique du bootstrap n'accorde toutes les actions. | lecture du fichier | `c9` toutes les actions accordées au rôle de déploiement |
| 10 | C10 | `make aws-apply` et `make aws-destroy` refusent de s'exécuter sans la … | contrôle scripté | `c10` apply sans confirmation explicite |
| 11 | C1 | `make sbom` produit l'inventaire de l'image au format CycloneDX dans `… | comportement : doit réussir + contrôle scripté | `c1` inventaire produit dans un autre format |
| 11 | C2 | `make sbom-scan` cherche les vulnérabilités à partir de l'inventaire s… | comportement : doit réussir + comportement : doit échouer + contrôle scripté | `c2` le scan de l'inventaire ne bloque plus |
| 11 | C3 | L'image de Prowler est épinglée par digest. | contrôle scripté | `c3` image Prowler sans digest |
| 11 | C4 | Le job `sbom` ne s'exécute pas sur les pull requests, appelle `make sb… | structure (Rego) | `c4` inventaire aussi produit sur les pull requests |
