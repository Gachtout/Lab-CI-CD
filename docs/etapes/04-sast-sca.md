# Étape 4 : SAST et SCA

## Objectif

Trouver automatiquement deux familles de failles : celles que tu as écrites (SAST) et celles que tu as importées (SCA).

## Le concept, depuis zéro

Une application, c'est quelques centaines de lignes à toi et des dizaines de milliers écrites par d'autres. Les deux peuvent être vulnérables, mais on ne les cherche pas de la même façon.

| | SAST | SCA |
|---|---|---|
| Ce qu'il analyse | Ton code source | La liste de tes dépendances |
| Sa question | « Ce code a-t-il une forme dangereuse ? » | « Cette version est-elle connue comme vulnérable ? » |
| Comment | Motifs et suivi des données de l'entrée utilisateur jusqu'à une fonction sensible | Comparaison nom + version avec une base de CVE |
| Sa faiblesse | Faux positifs, ne voit pas la logique métier | Ne dit pas si la fonction vulnérable est réellement appelée |
| La correction | Réécrire le code | Monter la version |

**SAST** : Semgrep cherche des *motifs*. Pour l'injection SQL, il suit la donnée : `request.args` (source contrôlée par l'utilisateur) rejoint une chaîne SQL construite à la main (puits). C'est une analyse de teinte.

**SCA** : Trivy lit `requirements.txt` et interroge une base de vulnérabilités. Le filtre `--ignore-unfixed` écarte les CVE sans correctif publié : bloquer un développeur sur un problème qu'il ne peut pas résoudre ne sert qu'à lui apprendre à ignorer l'outil.

## Ce qui t'est fourni

- Les images `SEMGREP_IMAGE` et `TRIVY_IMAGE` dans la plomberie.
- Les cibles `sast` et `sca`, vides.

## Énoncé

Livrables :

- Des règles Semgrep maison dans `.semgrep/`.
- Les cibles `make sast` et `make sca`, avec leurs variables de seuil.
- Les jobs `sast` et `sca` dans `pr-security.yml`.

Contraintes :

1. `make sast` réussit sur le code fourni et échoue sur une injection SQL : les jeux de règles communautaires pour Python et Flask sont utilisés.
2. Une règle maison bloque un secret de configuration écrit en dur (une clé de `app.config` dont le nom évoque un jeton, un secret, un mot de passe ou une clé, affectée à une chaîne littérale).
3. Une règle maison bloque l'activation en dur du mode debug de Flask.
4. Seuls les constats de sévérité `ERROR` font échouer `make sast` ; le seuil est porté par la variable `SEMGREP_SEVERITY`.
5. `make sca` réussit sur les dépendances fournies et échoue sur des dépendances ayant une vulnérabilité `HIGH` ou `CRITICAL` avec correctif disponible.
6. Le seuil de `make sca` est piloté par la variable `TRIVY_SEVERITY`, qui vaut `HIGH,CRITICAL` par défaut.
7. Les rapports SARIF sont écrits dans `reports/semgrep.sarif` et `reports/trivy-sca.sarif`.
8. Les jobs `sast` et `sca` appellent leur cible. Tout envoi de rapport vers Code Scanning a le droit nécessaire et ne peut pas faire échouer le job.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Règles maison | dossier `.semgrep/` |
| Cibles `make` | `sast`, `sca` |
| Variables de seuil | `SEMGREP_SEVERITY`, `TRIVY_SEVERITY` |
| Périmètre analysé | dossier `app/` |
| Rapports | `reports/semgrep.sarif`, `reports/trivy-sca.sarif` |
| Noms des jobs | `sast`, `sca` |

## Critère de réussite

```bash
make check-etape-04
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Semgrep charge des règles depuis un registre public (jeux nommés) et depuis des fichiers locaux ; on peut combiner plusieurs sources.
    - Trivy a un mode « système de fichiers » qui lit les fichiers de dépendances.

??? tip "Indice 2 : les points qui coincent"
    - Une règle Semgrep décrit un motif de code avec des métavariables ; une clause peut contraindre une métavariable par expression régulière.
    - Semgrep ne renvoie un code d'erreur que si on le lui demande, et on peut filtrer par sévérité.
    - Trivy sait ignorer les vulnérabilités sans correctif et choisir son code de sortie.
    - Un même scan peut être lancé deux fois : une fois pour le rapport, une fois pour le verdict.

??? tip "Indice 3 : presque la réponse"
    - Les jeux communautaires utiles ici s'appellent `p/python` et `p/flask`.
    - Règle « secret en dur » : un motif d'affectation à `$APP.config[$CLE]` d'une chaîne littérale, plus une contrainte sur `$CLE`.
    - Règle « debug » : deux motifs alternatifs, l'appel de lancement avec l'argument debug et l'affectation de la clé de configuration.
    - Regroupe les options de seuil de Trivy dans une variable du `Makefile` construite à partir de `TRIVY_SEVERITY` : tu la réutiliseras aux étapes 5 et 11.
    - Dans le job, l'envoi du rapport demande le droit d'écrire les événements de sécurité, et une option d'étape permet de continuer en cas d'erreur.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Remets la concaténation SQL de l'étape 2 et écris un jeton en dur dans la configuration. Quel outil attrape quoi ? Gitleaks a-t-il vu le jeton ?
2. Remplace les dépendances par des versions de 2022 de Flask et Werkzeug. Lis la colonne des versions corrigées.
3. Relance `make sca` en ne gardant que `CRITICAL` comme seuil. Que conclus-tu sur ce qu'est un seuil ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Quelle différence entre SAST et SCA ? Laquelle de leurs corrections coûte le plus ?
2. Qu'est-ce qu'une analyse de teinte ? Donne la source et le puits de l'injection SQL.
3. Pourquoi ignorer les vulnérabilités sans correctif disponible ? Quel est le risque de ce choix ?
4. La SCA dit qu'une bibliothèque est vulnérable. Qu'est-ce qu'elle ne dit pas ?
5. Pourquoi une règle maison plutôt que d'attendre que l'éditeur l'ajoute ?
6. Pourquoi l'envoi d'un rapport ne doit-il pas faire échouer un contrôle ?
7. Un développeur conteste un faux positif du SAST. Comment tranches-tu ?

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make sca` (Trivy fs) | `wizcli dir scan` : vulnérabilités des dépendances du répertoire |
| `make sast` (Semgrep) | Wiz Code propose une analyse SAST ; beaucoup d'entreprises gardent en parallèle un SAST dédié |
| Seuil `HIGH,CRITICAL` avec correctif | Politique de vulnérabilités : sévérité minimale, « fix available », délai de grâce |

Vérifie la syntaxe exacte de `wizcli` dans la documentation de ton tenant : les sous-commandes ont changé entre versions.

## Corrigé

À ouvrir seulement une fois `make check-etape-04` vert et les questions travaillées : [`etape-04-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-04-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le corrigé de cette étape envoie les rapports sans `continue-on-error` ni droit `actions: read` : corrigé après la première exécution réelle sur GitHub.
- Les rapports SARIF du corrigé de cette étape ne sont pas encore filtrés comme le seuil : aligné à l'étape 8.
