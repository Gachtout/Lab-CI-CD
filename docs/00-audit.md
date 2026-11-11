# Étape 0 : audit de l'existant (lab « VulnShop »)

- **Date** : 2026-11-10
- **Objet** : archive `devsecops-lab.zip` (56 fichiers, 2 871 lignes, pas d'historique git)
- **Méthode** : chaque composant a été exécuté, sur une copie de travail, avec les versions exactes épinglées par le lab. L'original n'a pas été modifié.
- **Verdict** : l'existant fonctionne, mais c'est un autre lab que celui visé. On réécrit, en récupérant quelques briques (détail en section 5).

## 1. Ce qu'est l'existant

Un lab **local, centré Gitea** : forge Gitea + runner `act_runner` + PostgreSQL (état Terraform), montés par `infra/bootstrap.sh`. Le pipeline (`devsecops.yml`, un seul fichier, 9 jobs) scanne une app Flask vulnérable, puis déploie un conteneur sur le Docker local avec le provider Terraform `kreuzwerker/docker`. Le Terraform AWS (`app/iac/`) n'est qu'analysé statiquement, jamais planifié ni appliqué.

La cible est : GitHub Actions, AWS réel via OIDC, état S3, rulesets GitHub, `make` 100 % Docker, site MkDocs, une étape = un commit + une page.

## 2. Environnement d'audit et ses limites

| Élément | Valeur |
|---|---|
| Machine | conteneur Linux (4 vCPU, 15 Go), Docker 29.9.2, sortie réseau via proxy TLS |
| Outils | Gitleaks 8.30.1, Trivy 0.76.1, Semgrep 1.183.0, Checkov 3.4.0, Hadolint 2.15.1, Terraform 1.17.1, TFLint 0.65.0, Conftest 0.71.1, actionlint 1.7.12, ZAP `stable` |

Trois écarts par rapport à ta machine, à garder en tête en lisant les résultats :

1. **Docker Hub a répondu 429** (rate limit). Les images de base `python:3.7-slim` et `python:3.13-slim` viennent du miroir `mirror.gcr.io`, avec le certificat du proxy ajouté. Les `Dockerfile` du lab ont été construits tels quels.
2. **Les jobs n'ont pas pu s'exécuter dans le runner Gitea** : le conteneur de job ne fait pas confiance au proxy TLS de mon bac à sable (`x509: certificate signed by unknown authority` au clonage de `actions/checkout`). Ce n'est pas un défaut du lab. J'ai donc exécuté **les commandes de chaque job à la main**, sur l'hôte, avec les mêmes binaires.
3. **Rien n'a été testé sous Windows / WSL2**, ni sur github.com, ni sur Bitbucket.

## 3. Résultats par composant

Légende : ✅ fonctionnel et vérifié · ⚠️ fonctionne avec un défaut · ❌ cassé · ➖ non vérifiable ici.

### 3.1 Épinglage et chaîne d'approvisionnement

| Composant | État | Preuve |
|---|---|---|
| Binaires épinglés + SHA-256 (Gitleaks, Trivy, Terraform, TFLint, Conftest) | ✅ | Les 5 téléchargements répondent 200 et `sha256sum -c` affiche `OK` pour chacun |
| Actions épinglées par SHA | ✅ | `git ls-remote` : `checkout@11d5960…` = v4.4.0, `upload-artifact@ea165f8…` = v4.6.2, `setup-python@a26af69…` = v5.6.0 |
| Révisions des hooks pre-commit | ✅ | Les 6 tags existent |
| Images Docker par digest | ❌ | Aucune image n'est épinglée par `@sha256`. Tags mobiles : `gitea/gitea:latest`, `gitea/act_runner:latest`, `catthehacker/ubuntu:act-latest`, `zaproxy:stable` |
| Fraîcheur des versions | ⚠️ | En retard : `actions/checkout` (v4.4.0, la v6.1.0 existe), Trivy (0.76.2), Checkov (3.4.3), Semgrep (1.185.0), TFLint (0.66.0). À jour : Gitleaks, Hadolint, Terraform, Conftest |
| `actionlint` sur le workflow | ✅ | Aucune erreur, code 0 |

Le README cite un incident Trivy de mars 2026 (CVE-2026-33634). Je ne l'ai pas revérifié dans cet audit : à sourcer dans l'ADR des outils.

### 3.2 Contrôles du pipeline (commandes des jobs rejouées à la main)

| Job | App vulnérable (`app/`) | App corrigée (`solutions/`) | État |
|---|---|---|---|
| Secrets (Gitleaks) | `no leaks found`, code 0 | code 0 | ⚠️ voir défaut D1 |
| SAST (Semgrep) | 17 findings, code 1 | 0 finding, code 0 | ✅ |
| SCA (Trivy fs) | 9 CVE (7 HIGH, 2 CRITICAL), code 1 | 0, code 0 | ✅ |
| SBOM CycloneDX | généré, 9 composants | généré, 10 composants | ✅ |
| IaC (Checkov) | 50 échecs (21 Terraform, 27 K8s, 2 Dockerfile), code 1 | 0 échec, 6 skips justifiés, code 0 | ⚠️ voir D3 |
| Hadolint | 3 warnings, code 1 | code 0 | ✅ |
| Terraform fmt / validate / TFLint / plan | tout passe, `Plan: 3 to add` | idem | ✅ |
| Policies OPA (Conftest) | 10 refus, code 1 ; tests unitaires 5/5 | 0 refus, 1 avertissement, code 0 | ✅ |
| Image (Trivy image) | 13 + 2 CRITICAL, code 1 | code 0 | ⚠️ voir D2 |
| DAST (ZAP baseline) | 3 règles FAIL, code 1 | 0 FAIL, 2 WARN, code 0 | ✅ |
| `security-gate` | logique lue, non exécutée | — | ➖ |
| `deploy-staging` (apply sur Docker) | non exécuté | — | ➖ |

Le rouge sur `app/` et le vert sur `solutions/` sont donc réels pour 9 contrôles sur 10. L'affirmation du README « corrigés vérifiés » est exacte.

Extrait réel, policies OPA sur le plan de l'app vulnérable :

```text
FAIL - tfplan.json - terraform.conteneurs - [TF-02] docker_container.app : conteneur privilégié interdit (privileged = false)
FAIL - tfplan.json - terraform.conteneurs - [TF-03] docker_container.app : le port 8080 est publié sur toutes les interfaces, ajoute ip = "127.0.0.1"
FAIL - tfplan.json - terraform.variables - [TF-01] variable "secret_key" : pas de valeur par défaut pour un secret (fournis-la via TF_VAR_secret_key)
11 tests, 1 passed, 0 warnings, 10 failures, 0 exceptions
```

### 3.3 Application

| Point | État | Preuve |
|---|---|---|
| L'image vulnérable se construit et démarre | ✅ | `/` répond 200 |
| Injection de commande (`/ping?host=127.0.0.1;id`) | ✅ exploitable | 200 sur le vulnérable, 400 sur le corrigé |
| SSTI (`/hello?name={{7*7}}`) | ✅ exploitable | `Bonjour 49 !` sur le vulnérable, `{{7*7}}` littéral sur le corrigé |
| Injection SQL (`/user`) | ❌ | La route plante : `TypeError: 'dict' object is not callable`. Flask 0.12.2 ne sait pas renvoyer un `dict`. Semgrep la détecte, mais elle n'est pas démontrable |
| En-têtes de sécurité du corrigé | ✅ | CSP, `X-Frame-Options: DENY`, `nosniff` présents |
| Conteneur corrigé non-root | ✅ | `user=appuser` |

### 3.4 Plateforme Gitea

| Composant | État | Preuve |
|---|---|---|
| `bootstrap.sh` | ✅ | Stack complète en 15 s (images déjà en cache), compte, dépôt, hook, secrets CI, protection de branche créés |
| Hook serveur pre-receive (Gitleaks) | ✅ | Push d'un jeton `ghp_…` avec `--no-verify` : `PUSH REFUSÉ`, `pre-receive hook declined` |
| Protection de branche | ⚠️ | Créée, mais `enable_push: true` et `required_approvals: 0` : voir D4 |
| Runner | ✅ en partie | Enregistré, 16 jobs distribués sur 2 pushes. Contenu des jobs non vérifiable ici (limite 2 de la section 2) |
| `infra/platform` (forge en Terraform) | ✅ | `validate` OK, `Plan: 2 to import, 0 to add, 1 to change, 0 to destroy` |
| `reset.sh` | ➖ | Demande une confirmation interactive, non lancé. Démontage fait par `docker compose down -v` |

### 3.5 Non vérifié

- `bitbucket-pipelines.yml` : lu, jamais exécuté (pas de compte Bitbucket).
- Le workflow sur github.com : seulement `actionlint`.
- Les hooks pre-commit de bout en bout : configuration lue et révisions vérifiées, `pre-commit run` non lancé.
- Exercices 15 (verrou, dérive) et 16 (au-delà du `plan`).

## 4. Défauts constatés

| # | Défaut | Conséquence pour la cible |
|---|---|---|
| D1 | **Le job Secrets est vert sur l'app vulnérable.** Les « secrets » du lab (`super-secret-key-123`, `Password123!`, `API_TOKEN=changeme`) ne déclenchent aucune règle Gitleaks. J'ai aussi poussé les clés d'exemple AWS (`AKIAIOSFODNN7EXAMPLE`) : acceptées, Gitleaks les ignore volontairement. | La démo « PR bad = secret bloqué » ne marcherait pas. Il faut un secret factice qui déclenche vraiment une règle, à tester avant de l'écrire dans la doc |
| D2 | **Seuil image trop laxiste** : seul CRITICAL bloque. L'image « corrigée » garde 7 CVE HIGH avec correctif disponible. | Contraire à la règle visée (HIGH et CRITICAL corrigeables bloquent) |
| D3 | **Checkov sans seuil** : les 50 échecs bloquent tous, y compris du bruit (réplication inter-régions, notifications S3). Skips sans date d'expiration. | Pas de quality gate explicite, pas d'équivalent aux ignore rules Wiz |
| D4 | **Le push direct sur `main` est autorisé par défaut.** Mon push sur `main` est passé sans PR. Le blocage n'existe qu'après l'exercice 10, fait à la main. | La « vraie barrière » n'est pas en place par défaut |
| D5 | La route SQLi plante (voir 3.3). | À corriger si on garde l'app |
| D6 | Un seul workflow monolithique, déclenché sur `push` de toutes les branches **et** sur `pull_request` : chaque PR lance le pipeline deux fois. | La cible demande 4 workflows séparés |
| D7 | `permissions: contents: read` global uniquement. Ni permissions par job, ni upload SARIF vers Code Scanning, ni commentaire de PR, ni `environment`, ni `concurrency`. | Tout cela est demandé |
| D8 | `app/iac/` : pas de `required_providers`, pas de fichier de verrouillage, hors du `terraform fmt` du pipeline. Contient une instance RDS (hors périmètre free tier visé). | Inutilisable comme base du Terraform AWS réel |
| D9 | Aucune auth cloud : ni OIDC, ni état S3, ni bootstrap, ni budget, ni destroy. | Étapes 6 et 10 entièrement à écrire |
| D10 | Pas de `Makefile` : les outils s'installent sur le poste (Terraform, TFLint, pre-commit, WSL2, ligne dans `hosts`). | Le « rejouable en 15 min via `make` » n'existe pas |
| D11 | Pas de `docs/`, pas de MkDocs, pas d'ADR, pas de licence. Le README mélange guide et exercices (377 lignes). | Documentation portfolio à écrire |
| D12 | Composants hors périmètre : Kubernetes (`k8s/`), Bitbucket, DAST ZAP, PostgreSQL, provider Docker. | Tu as exclu K8s ; le reste n'est pas demandé |

## 5. Recommandation : réécrire, en récupérant quatre briques

L'existant est de bonne qualité technique. Il gêne pourtant plus qu'il n'aide, pour trois raisons :

1. **Mauvaise plateforme.** Environ 60 % du code sert Gitea, le provider Docker, PostgreSQL, Bitbucket ou Kubernetes. Rien de cela n'existe dans la cible.
2. **Pas d'historique.** Il n'y a aucun commit. Le découper après coup en 11 étapes « un commit + une page » revient à tout réécrire, en plus fragile.
3. **Tu ne l'as pas construit.** Ton objectif est de savoir intégrer Wiz en pipeline. Un lab généré d'un bloc et retouché ne t'apprend pas à écrire un workflow.

| Élément | Décision | Justification |
|---|---|---|
| `app/app.py`, `requirements.txt`, `Dockerfile` | **Refactorer** | Failles réelles et vérifiées. À faire : corriger la route SQLi (D5), ajouter un secret factice détectable (D1), rendre les failles activables, réduire de 16 à celles demandées |
| `solutions/` (app et Dockerfile) | **Réutiliser** comme base de la PR « fix » | Vérifié vert sur tous les contrôles |
| Table des versions et des SHA-256 | **Réutiliser** comme point de départ | Tout est valide. À rafraîchir et à convertir en digests d'images |
| `.semgrep/regles-maison.yml` | **Réutiliser** | 3 règles qui se déclenchent, bon support pour l'étape 4 |
| Motif du job `security-gate` | **Réutiliser** l'idée | Un seul statut requis qui agrège les jobs : c'est le bon schéma pour les required status checks |
| Policies Rego (`deploy/policy/`) | **Réécrire** | Bien faites et testées, mais elles ciblent `docker_container`. Le piège `null` documenté reste une bonne leçon à reprendre |
| `app/iac/main.tf` | **Réécrire** en modules | D8. Les mauvaises configurations S3 et security group serviront d'inspiration pour la PR « bad » |
| Workflow `devsecops.yml` | **Réécrire** | D6, D7. Construit étape par étape, c'est le cœur de l'apprentissage |
| `.pre-commit-config.yaml` | **Refactorer** | Bonne base, à réduire à ce que tu as demandé (Gitleaks, terraform fmt/validate, Trivy config) |
| `infra/` (Gitea, runner, hook, platform) | **Écarter** | Hors cible. Le hook pre-receive reste un bon paragraphe pour la page « branch protection » (ce que GitHub.com ne permet pas) |
| `k8s/`, Bitbucket, ZAP, `deploy/` (provider Docker) | **Écarter** | Hors périmètre |
| README | **Réécrire** | D11 |

## 6. Décisions que j'attends de toi avant l'étape 1

1. **Go sur « réécrire + récupérer les quatre briques »**, ou tu préfères garder davantage de l'existant ?
2. **DAST (ZAP)** : il fonctionne, mais il n'est pas dans ta cible. Je l'écarte, sauf avis contraire.
3. **Nom et visibilité du dépôt GitHub** : le lab doit être public pour que Code Scanning, le secret scanning avec push protection et les rulesets soient gratuits. Ce sera le premier point de contrôle de l'étape 1.
