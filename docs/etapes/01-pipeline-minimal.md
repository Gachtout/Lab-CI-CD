# Étape 1 : un pipeline minimal

## Objectif

Avoir un premier workflow GitHub Actions qui se déclenche, exécute une commande et conserve un fichier. Aucun contrôle de sécurité pour l'instant : on apprend la mécanique.

## Le concept, depuis zéro

Une chaîne CI/CD répond à un problème simple : **« ça marche sur ma machine » n'est pas une preuve**. On veut qu'une machine neutre rejoue les vérifications à chaque changement, sans intervention humaine, et que le résultat soit visible de tous.

GitHub Actions le fait avec quatre notions.

| Notion | Ce que c'est réellement |
|---|---|
| **Event** | Un fait qui se produit dans le dépôt (`pull_request`, `push`…). GitHub lit alors les fichiers de `.github/workflows/` et lance ceux dont le bloc `on:` correspond |
| **Runner** | Une machine virtuelle neuve, créée pour le job et détruite après. Rien ne survit d'un job à l'autre |
| **Job** | Une suite d'étapes exécutées sur un même runner. Deux jobs tournent sur deux machines différentes, en parallèle par défaut |
| **Artifact** | Un fichier qu'on demande explicitement à GitHub de conserver, puisque le runner est détruit |

Deux conséquences pratiques :

- Le runner part d'un disque vide : il faut d'abord récupérer le code (`actions/checkout`).
- Le code de sortie de chaque commande décide de tout. `0` : l'étape est verte. Autre chose : l'étape, puis le job, sont rouges. **Tous les blocages de ce lab reposent sur ce mécanisme.**

## Ce qu'on fait

1. Un `Makefile` dont chaque cible lance un outil dans une image Docker épinglée par digest.
2. Un workflow `pr-security.yml` avec un seul job, `workflow-lint`, qui appelle `make lint-workflows` puis publie le rapport en artifact.

Le workflow ne contient donc presque aucune logique : il appelle `make`. C'est ce qui garantit que le local et la CI font la même chose.

```yaml title=".github/workflows/pr-security.yml (extrait)"
permissions: {}            # aucun droit par défaut

jobs:
  workflow-lint:
    runs-on: ubuntu-24.04
    permissions:
      contents: read       # lire le code, rien d'autre
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - run: make lint-workflows
      - if: always()
        uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
```

Trois choix à savoir justifier :

- **Action épinglée par SHA de commit**, pas par tag. Un tag (`v7`) peut être déplacé vers un autre commit par quiconque contrôle le dépôt de l'action ; un SHA ne peut pas.
- **`permissions: {}`** au niveau du workflow. Le jeton `GITHUB_TOKEN` donné au runner n'a alors aucun droit, sauf ceux que chaque job redemande.
- **`persist-credentials: false`** : le jeton n'est pas laissé dans la configuration git du runner après le checkout.

## Comment vérifier

En local :

```bash
make lint-workflows
```

Sortie attendue : aucune ligne d'erreur, code de sortie `0`, fichier `reports/actionlint.txt` vide.

Sur GitHub (après le [point de contrôle 1](../reference/checkpoints.md)) : onglet **Actions**, workflow `pr-security`, job `workflow-lint` vert, et un artifact `actionlint` téléchargeable en bas de la page d'exécution.

## Casse-le volontairement

Dans `pr-security.yml`, remplace `ubuntu-24.04` par `ubuntu-99.99`, puis relance `make lint-workflows`.

```text
.github/workflows/pr-security.yml:23:14: label "ubuntu-99.99" is unknown. available labels are
"windows-latest", …, "ubuntu-24.04", … [runner-label]
make: *** [Makefile:59: lint-workflows] Error 1
```

`make` renvoie un code non nul : dans la CI, le job serait rouge. Deuxième essai, plus instructif : remplace la commande par `echo ${{ github.event.pull_request.title }}`.

```text
.github/workflows/pr-security.yml:32:23: "github.event.pull_request.title" is potentially untrusted.
avoid using it directly in inline scripts. instead, pass it through an environment variable. [expression]
```

actionlint a détecté une **injection de script** : le titre d'une PR est écrit par un inconnu et serait collé tel quel dans une commande shell. Annule tes modifications avec `git checkout .github/workflows/pr-security.yml`.

## Côté Wiz, en entreprise

Wiz n'exécute pas ton pipeline : il s'y **branche**. Wiz CLI est un binaire qu'on appelle depuis un job, comme on appelle ici `make`. Tout ce qui est appris à cette étape (events, permissions du jeton, code de sortie, artifacts) est donc le socle sur lequel l'intégration Wiz reposera, quel que soit l'outil de CI de l'entreprise.
