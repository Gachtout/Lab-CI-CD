# ADR 0001 : architecture du lab

- **Statut** : accepté
- **Date** : 2026-11-11

## Contexte

Le lab doit apprendre la CI/CD à quelqu'un qui n'en a jamais fait, préparer une intégration de Wiz en entreprise, et être rejouable par un recruteur en moins de 15 minutes sans compte AWS. Un lab existant (« VulnShop ») a été audité à l'[étape 0](../00-audit.md).

## Décisions

### 1. Réécrire plutôt que retoucher l'existant

L'existant fonctionnait, mais visait une autre plateforme (Gitea, provider Docker, PostgreSQL) et n'avait aucun historique. Quatre briques ont été reprises : l'idée de l'application Flask et de son corrigé, la table des versions épinglées, les règles Semgrep maison, le motif du job `security-gate`. Le DAST (ZAP), Kubernetes et Bitbucket sont écartés : hors périmètre.

### 2. Le `Makefile` est la seule source de vérité

Chaque contrôle est une cible `make` qui lance un outil dans une image Docker épinglée par digest. Les workflows n'appellent que `make`.

- **Pour** : ce qui est vert en local est vert en CI ; aucun outil à installer hormis Docker et `make` ; très peu d'actions tierces (cinq, toutes épinglées par SHA), donc peu de surface d'attaque côté chaîne d'approvisionnement.
- **Contre** : pas de cache de couches entre jobs, donc des exécutions un peu plus longues ; sous Windows, il faut WSL2 ou Git Bash.

### 3. Images hors de Docker Hub quand c'est possible

Pendant la construction du lab, Docker Hub a répondu `429 Too Many Requests` à plusieurs reprises. L'image de base de l'application vient de `public.ecr.aws`, Trivy, Gitleaks et Checkov de `ghcr.io`. Pour les outils qui n'existent que sur Docker Hub (Semgrep, Terraform, Conftest, actionlint), la variable `DOCKERHUB` permet de passer par un miroir (`make scan DOCKERHUB=mirror.gcr.io`). Le digest étant l'empreinte du contenu, il est identique quel que soit le registre.

### 4. Aucun identifiant AWS sur une pull request

Le plan des PR est calculé **hors ligne** (`skip_credentials_validation`, faux identifiants, backend local jetable). Les rôles AWS ne sont endossables que depuis les environnements GitHub `dev-plan` et `dev`, eux-mêmes limités à la branche `main`.

- **Pour** : une PR, y compris depuis un fork, ne peut rien obtenir d'AWS ; le lab se rejoue sans compte.
- **Contre** : le plan d'une PR ne voit ni la dérive ni l'état réel. Le plan réel n'apparaît qu'après fusion, avant l'approbation de l'apply.

### 5. Deux rôles AWS, deux environnements

`dev-plan` (lecture seule, sans approbation) et `dev` (écriture, approbation manuelle). L'approbateur voit le plan réel avant de valider. Le job `apply` recalcule son plan au lieu d'appliquer un fichier de plan transmis : sur un dépôt public, un artifact est téléchargeable par tout compte connecté, et un plan contient des identifiants de compte.

### 6. Verrou d'état natif S3

`use_lockfile = true` (Terraform ≥ 1.10) remplace la table DynamoDB : une ressource de moins à créer.

### 7. Les failles de démonstration ne sont pas dans `main`

`main` est sain. Les failles sont dans `demo/bad.patch`, appliqué à la demande ; le secret factice est assemblé par le script. Aucun scanner n'a donc de dossier à exclure, et la push protection de GitHub ne peut pas bloquer le dépôt lui-même.

## Conséquences

- Le lab se rejoue avec `make demo-good` et `make demo-bad`.
- Tout ce qui dépend de GitHub ou d'AWS (étapes 9 et 10) n'a pas pu être exécuté au moment de l'écriture : voir les pages des étapes 9 et 10.
