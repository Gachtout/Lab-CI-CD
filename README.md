# Lab DevSecOps : construis ta chaîne CI/CD, étape par étape

> [!NOTE]
> **Branche `exercices`.** Ici, rien n'est écrit à ta place : tu construis la chaîne en 11 étapes et une commande te dit si ton implémentation tient. Le corrigé complet est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution), à ouvrir après.

Tu vas construire une chaîne **GitHub Actions + Terraform (AWS free tier)** qui refuse la fusion d'un changement contenant un secret, une injection SQL, une dépendance ou une image vulnérable, un bucket public ou un security group ouvert. Les outils sont gratuits et reproduisent ce que fait Wiz CLI dans un pipeline.

## Ce qui est fourni, ce qui est à toi

| Fourni | À écrire |
|---|---|
| L'application Flask et ses tests (`app/`) | Le `Dockerfile` |
| La plomberie Docker du `Makefile` : images épinglées par digest, variable `RUN`, proxy | Toutes les cibles marquées `[À FAIRE]`, et les seuils |
| `scripts/` : synthèse, scan global, format des exceptions, commentaire de PR | Les quatre workflows GitHub Actions |
| `checks/` : les vérifications de chaque étape | Les règles Gitleaks et Semgrep, les policies Rego et leurs tests |
| Les pages d'énoncé (`docs/etapes/`) | Les modules Terraform, le bootstrap AWS, le ruleset et son script |

## Prérequis

Docker, `make`, `bash`, `git`. Sous Windows : WSL2. Aucun compte AWS avant l'étape 10. Le premier lancement télécharge environ 3,5 Go d'images ; si Docker Hub limite le débit, ajoute `DOCKERHUB=mirror.gcr.io` à tes commandes `make`.

## Comment travailler

1. Lis la page de l'étape dans [`docs/etapes/`](docs/etapes/) : objectif, concept, énoncé, contraintes numérotées, contrat d'interface.
2. Implémente.
3. Vérifie en local :

    ```bash
    make check-etape-01
    ```

    Une ligne `ECHEC [C3] … (fichier:ligne)` renvoie à la contrainte 3 de l'énoncé et à l'emplacement en cause. Elle ne donne jamais la correction. Les journaux sont dans `reports/checks/`.

4. Bloqué ? Ouvre les indices de la page, dans l'ordre : du plus vague au plus précis.
5. Travaille les questions « Défends ton choix » à l'oral, puis note tes observations dans [`docs/journal.md`](docs/journal.md).
6. Seulement ensuite, compare avec le corrigé de l'étape (lien en bas de chaque page).
7. Pousse, ouvre une PR, regarde ton pipeline tourner.

Les étapes s'enchaînent : chacune s'appuie sur ce que tu as écrit avant. `make check-tout` rejoue toutes les vérifications dans l'ordre et s'arrête à la première non validée.

| # | Étape | Tu écris |
|---|---|---|
| 1 | [Pipeline minimal](docs/etapes/01-pipeline-minimal.md) | Ton premier workflow, la cible de lint |
| 2 | [Build, tests, Docker](docs/etapes/02-build-test-docker.md) | Le `Dockerfile`, les cibles de test et de build |
| 3 | [Secrets](docs/etapes/03-secrets.md) | La configuration Gitleaks, une règle maison, un hook |
| 4 | [SAST et SCA](docs/etapes/04-sast-sca.md) | Des règles Semgrep, les seuils |
| 5 | [Image](docs/etapes/05-image.md) | Le scan d'image, le durcissement |
| 6 | [Terraform](docs/etapes/06-terraform.md) | Les modules, l'environnement, le plan hors ligne |
| 7 | [Scan IaC et policies](docs/etapes/07-iac-policies.md) | Les scanners IaC, quatre policies Rego testées |
| 8 | [Quality gates](docs/etapes/08-quality-gates.md) | Les exceptions, le verdict, le commentaire de PR |
| 9 | [Protection de branche](docs/etapes/09-branch-protection.md) | Le ruleset et son script |
| 10 | [OIDC, apply, destroy](docs/etapes/10-oidc-deploy.md) | Le bootstrap AWS, les rôles, le déploiement |
| 11 | [SBOM et Prowler](docs/etapes/11-prowler-sbom.md) | L'inventaire, l'audit du compte |

## Ce que les vérifications ne font pas

- Elles n'exécutent rien sur GitHub ni sur AWS. Les étapes 9 et 10 ne sont vérifiées qu'en **statique** : chaque page liste ce que tu dois tester toi-même.
- Elles ne lancent jamais tes cibles `aws-*` ni `prowler`, et retirent de leur environnement tout identifiant AWS.
- Elles vérifient un comportement, pas une écriture : deux solutions différentes peuvent passer. En contrepartie, les noms du « contrat d'interface » de chaque page sont imposés.
- Lire `checks/etape-XX.sh` avant de faire l'étape te donne des indices. C'est ton parcours : à toi de voir.

## Faire le parcours dans ton propre dépôt, sans l'historique de celui-ci

Le parcours se fait dans un dépôt à toi, dont `main` part du squelette. Crée d'abord un dépôt **vide** sur GitHub (sans README ni licence), puis :

```bash
git clone --branch exercices --depth 1 https://github.com/Gachtout/Lab-CI-CD.git mon-pipeline
cd mon-pipeline
rm -rf .git
git init -b main
git add -A
git commit -m "chore: squelette du lab DevSecOps"
git remote add origin git@github.com:<ton-compte>/<ton-depot>.git
git push -u origin main
```

Ce que fait chaque commande :

| Commande | Effet |
|---|---|
| `git clone --branch exercices --depth 1` | Ne récupère que le dernier état de la branche d'exercices |
| `rm -rf .git` | Supprime tout lien avec ce dépôt : historique, branches, corrigé |
| `git init -b main` puis `add` et `commit` | Crée un historique neuf d'un seul commit : le tien commence ici |
| `git remote add` puis `git push` | Envoie le squelette sur ton dépôt |

Dans ton dépôt, travaille sur des branches et ouvre des pull requests vers `main` : c'est ce que tes workflows attendent.

Deux conséquences de cette séparation :

- les liens « Corrigé » des pages pointent vers `Gachtout/Lab-CI-CD` ;
- `make test-checks` n'y fonctionne pas : il a besoin de la branche `solution`. C'est un outil de mainteneur, pas d'apprenant.

## Pour qui maintient ce dépôt

`make test-checks` éprouve les vérifications elles-mêmes, à partir de la branche `solution` :

- chaque vérification **passe** sur le corrigé et **échoue** sur le squelette ;
- chaque vérification **échoue** sur chacun de ses mutants (`checks/mutants/`), un mutant retirant une seule contrainte du corrigé, et l'échec cite la bonne contrainte ;
- progression : avec les étapes 1 à N résolues, la vérification N passe et la N+1 échoue ;
- cohérence : chaque contrainte numérotée d'une page a un contrôle et un mutant (`reports/correspondance.md`) ;
- fuite : aucune ligne du corrigé ne figure sur cette branche.

```bash
git fetch origin solution
make test-checks                       # tout, compter 45 à 60 minutes
make test-checks STEPS="03" PARTS=mutants
```

Les mutants sont des transformations appliquées à la volée au corrigé (`checks/tools/mut.py`), jamais des fichiers complets.

## Branches du dépôt

| Branche | Contenu |
|---|---|
| `main` | Le lab en mode démonstration (produit fini) |
| `exercices` | Ce squelette |
| `solution` | Le corrigé complet |
| `etape-01-solution` … `etape-11-solution` | L'état du corrigé à la fin de chaque étape |

## Licence

[MIT](LICENSE).
