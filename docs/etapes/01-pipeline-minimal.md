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

## Ce qui t'est fourni

- Le `Makefile` avec sa plomberie Docker : la variable `RUN` et l'image `ACTIONLINT_IMAGE`, épinglée par digest.
- Une cible `lint-workflows` vide, qui échoue avec « non implémenté ».

## Énoncé

Livrables :

- La cible `make lint-workflows` : elle lance actionlint, dans son image Docker, sur les workflows du dépôt.
- Le workflow `.github/workflows/pr-security.yml`, avec un seul job.

Contraintes :

1. Le workflow se déclenche sur les pull requests visant `main`, sur les push sur `main`, et à la demande. Rien d'autre.
2. Le jeton du workflow n'a aucun droit par défaut. Chaque job déclare les siens ; `workflow-lint` n'a que la lecture du code.
3. Toute action tierce est épinglée par SHA de commit complet.
4. Le jeton ne reste pas dans la configuration git du runner après la récupération du code.
5. Le job n'installe aucun outil : il appelle `make lint-workflows`.
6. Le rapport est publié en artifact même si le lint échoue, et conservé 7 jours.
7. Chaque job a une durée maximale explicite.
8. Un nouveau push sur la même référence annule l'exécution précédente.
9. `make lint-workflows` écrit sa sortie dans `reports/actionlint.txt` et échoue si actionlint trouve une erreur, bien que la sortie passe par un tube.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Fichier du workflow | `.github/workflows/pr-security.yml` |
| Nom du job | `workflow-lint` |
| Cible `make` | `lint-workflows` |
| Rapport | `reports/actionlint.txt` |

## Critère de réussite

```bash
make check-etape-01
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Un workflow a quatre blocs de premier niveau qui comptent ici : ce qui le déclenche, les droits du jeton, la concurrence, les jobs. Repère la clé de chacun dans la référence « workflow syntax » de GitHub.
    - Pour la cible `make`, regarde comment la variable `RUN` est construite : elle monte le dépôt dans le conteneur.

??? tip "Indice 2 : les points qui coincent"
    - Les droits se règlent à deux niveaux, le workflow et le job. Le niveau job remplace le niveau workflow.
    - Pour trouver le SHA d'un tag sans faire confiance à une page web : `git ls-remote --tags` sur le dépôt de l'action.
    - Une étape ne s'exécute pas si une étape précédente a échoué, sauf condition explicite.
    - Les options de shell déclarées en tête du `Makefile` répondent à la contrainte 9.

??? tip "Indice 3 : presque la réponse"
    - Droits : un objet vide au niveau du workflow, puis la lecture du contenu au niveau du job.
    - L'action de récupération du code a une option qui concerne la persistance des identifiants.
    - La condition qui force une étape à s'exécuter quoi qu'il arrive est une fonction d'expression sans argument.
    - La concurrence se définit par un nom de groupe, construit à partir de la référence git, et un booléen d'annulation.
    - La cible `make` tient en une ligne : la variable `RUN`, l'image, un tube vers `tee`.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Remplace le système du runner par une version qui n'existe pas, puis relance `make lint-workflows`. Que renvoie `make` ?
2. Dans une étape `run`, affiche directement le titre de la pull request avec une expression. Que dit actionlint, et pourquoi est-ce une faille ?
3. Retire l'option `pipefail` du `Makefile` et refais le premier essai. Qu'est-ce qui change dans le code de sortie ? Remets l'option.

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Pourquoi épingler une action par SHA plutôt que par numéro de version ? Cite un incident réel où un tag a été déplacé.
2. Sans la ligne qui vide les droits, que peut faire le jeton par défaut, et qu'en ferait une action compromise ?
3. Deux jobs partagent-ils leur système de fichiers ? Comment un fichier passe-t-il de l'un à l'autre ?
4. Quelle différence de risque entre les déclencheurs `pull_request` et `pull_request_target` ?
5. Pourquoi appeler `make` plutôt qu'une action du marketplace qui ferait le lint ? Donne un avantage et un inconvénient.
6. Que se passe-t-il, côté sécurité, si un contributeur externe ouvre une PR qui modifie ce workflow ?
7. Pourquoi un tube peut-il rendre vert un contrôle qui a échoué ?

## Côté Wiz, en entreprise

Wiz n'exécute pas ton pipeline : il s'y **branche**. Wiz CLI est un binaire qu'on appelle depuis un job, comme on appelle ici `make`. Tout ce qui est appris à cette étape (events, permissions du jeton, code de sortie, artifacts) est donc le socle sur lequel l'intégration Wiz reposera, quel que soit l'outil de CI de l'entreprise.

## Corrigé

À ouvrir seulement une fois `make check-etape-01` vert et les questions travaillées : [`etape-01-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-01-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le corrigé de cette étape ne force pas encore `bash` comme shell des étapes `run` : c'est ajouté à l'étape 7.
