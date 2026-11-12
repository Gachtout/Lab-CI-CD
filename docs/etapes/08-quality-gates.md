# Étape 8 : quality gates, exceptions et verdict

## Objectif

Transformer une collection de scanners en une **décision** : ce changement peut-il être fusionné, oui ou non ? Et prévoir la sortie de secours légitime : l'exception tracée.

## Le concept, depuis zéro

Un scanner produit des constats. Un constat ne bloque rien tant qu'on n'a pas répondu à trois questions.

1. **Quel seuil ?** Tout bloquer rend l'outil insupportable : les équipes le désactivent. Ne rien bloquer le rend décoratif. Un seuil utile bloque ce qui est **grave et corrigeable**.
2. **Par quel mécanisme ?** Le code de sortie. Un gate est une commande qui renvoie `0` ou autre chose, rien de plus.
3. **Que fait-on des cas légitimes ?** Il y en a toujours. Sans procédure d'exception, les gens contournent le contrôle en entier. Une exception saine a un **périmètre** (quelle règle, quelle ressource), une **justification** et une **date de fin**. Sans date, elle devient permanente et plus personne ne sait pourquoi elle existe.

## Ce qui t'est fourni

- `scripts/check-exceptions.sh` : vérifie le format et l'expiration des exceptions. Lis-le pour connaître le format attendu.
- `scripts/scan-all.sh` : lance tous les contrôles sans s'arrêter au premier échec et écrit `reports/gates.json`.
- `scripts/summary.py` : construit `reports/summary.md` et renvoie le verdict.
- `scripts/pr-comment.sh` : publie ou met à jour un commentaire de PR.
- Les cibles `exceptions`, `scan`, `summary`, vides.

## Énoncé

Livrables :

- Les cibles `make exceptions`, `make scan`, `make summary`.
- Les jobs `exceptions` et `security-gate` dans `pr-security.yml`.
- La publication de la synthèse en commentaire de PR : c'est entièrement à ta charge (droits, condition, données non fiables).

Contraintes :

1. `make exceptions` réussit sur ton dépôt, et un job `exceptions` l'appelle.
2. `make exceptions` échoue si une exception n'a pas de date d'expiration, ou si elle a expiré.
3. Les seuils par défaut sont ceux du lab : vulnérabilités `HIGH` et `CRITICAL` avec correctif disponible, SAST à `ERROR`.
4. Le job `security-gate` s'exécute même quand un contrôle a échoué.
5. Le job `security-gate` dépend de tous les contrôles : `workflow-lint`, `build-test`, `secrets`, `sast`, `sca`, `image`, `iac`, `exceptions`.
6. `make summary` reçoit le résultat des jobs par la variable d'environnement `NEEDS_JSON` et échoue si un seul résultat n'est pas un succès, y compris « sauté ».
7. `make scan` lance tous les contrôles en local, ne s'arrête pas au premier échec, et échoue si l'un d'eux échoue.
8. Seul le job `security-gate` peut écrire sur les pull requests, et il ne commente que les PR venant du dépôt lui-même.
9. Aucune donnée non fiable de la pull request (titre, description, nom de branche) n'est insérée dans un script.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Cibles `make` | `exceptions`, `scan`, `summary` |
| Fichier d'exceptions de Trivy | `.trivyignore.yaml`, à la racine |
| Variable d'entrée du verdict | `NEEDS_JSON` (le contexte `needs` du job, en JSON) |
| Rapports | `reports/gates.json`, `reports/summary.md` |
| Noms des jobs | `exceptions`, `security-gate` |
| Format d'une exception Checkov | voir l'en-tête de `scripts/check-exceptions.sh` |

## Critère de réussite

```bash
make check-etape-08
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Un job dont un prérequis échoue est sauté. Demande-toi ce que la protection de branche pense d'un statut sauté.
    - Les trois scripts fournis font le travail ; ton rôle est de les brancher et de leur passer les bonnes entrées.

??? tip "Indice 2 : les points qui coincent"
    - Une expression GitHub Actions convertit un contexte en JSON ; une variable d'environnement d'étape la transmet à la commande.
    - La variable doit encore traverser `docker run` pour atteindre le script.
    - Le jeton d'une PR venant d'un fork est en lecture seule : une condition doit écarter ce cas avant de commenter.
    - Une valeur écrite par un inconnu ne doit jamais être collée dans une commande shell : passe par l'environnement.

??? tip "Indice 3 : presque la réponse"
    - Le job final combine une condition « toujours » et la liste de ses prérequis.
    - Les artifacts des autres jobs se récupèrent en une étape, par motif de nom, avant de construire la synthèse.
    - Pour reconnaître une PR interne, compare le nom complet du dépôt source de la PR à celui du dépôt courant.
    - `scripts/pr-comment.sh` attend trois variables d'environnement, dont le numéro de la PR.
    - Le droit d'écrire sur les pull requests se déclare au niveau du seul job qui commente.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Lance `make exceptions` en te plaçant dans le futur (le script accepte une date du jour en variable d'environnement).
2. Retire la date d'une exception. Puis fais expirer une entrée du fichier d'exceptions de Trivy et relance le scan IaC.
3. Retire la condition « toujours » du job final : que devient son statut quand un contrôle échoue ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Qu'est-ce qui distingue un seuil utile d'un seuil décoratif ou insupportable ?
2. Pourquoi une exception doit-elle avoir une date de fin ?
3. Pourquoi un seul statut agrégé plutôt que neuf statuts requis ?
4. Pourquoi un job sauté doit-il compter comme un échec ?
5. Le titre d'une PR est une donnée non fiable. Décris l'attaque si on l'insère dans un script.
6. Pourquoi ne pas donner le droit de commenter à tous les jobs ?
7. Tes seuils sont dans le dépôt : une PR peut les baisser. Quelles parades ?

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| Seuils dans le `Makefile` | **Politiques de CI/CD**, définies dans la console et attachées à un projet. `wizcli` les télécharge à chaque scan : le seuil ne vit pas dans le dépôt |
| Code de sortie de `make` | Code de sortie de `wizcli` : non nul si la politique est en mode blocage et qu'elle est violée |
| Mode « rapport seul » | Politique en mode audit : le pipeline reste vert, les constats remontent. Utile pour déployer sans tout casser le premier jour |
| `.trivyignore.yaml`, `checkov:skip` | **Ignore rules** : périmètre, justification, expiration, le tout tracé et soumis à des droits |
| `security-gate` | Inchangé : le job qui appelle `wizcli` devient un statut requis |

Différence d'organisation importante : avec Wiz, c'est l'équipe sécurité qui tient les seuils, pas le développeur qui édite un fichier dans sa propre PR. Dans ce lab, une PR peut modifier le `Makefile` pour baisser un seuil. L'étape 9 traite ce point avec les fichiers protégés (`CODEOWNERS`).

## Corrigé

À ouvrir seulement une fois `make check-etape-08` vert et les questions travaillées : [`etape-08-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-08-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le corrigé contient aussi une démonstration rouge / vert et un job d'auto-test des contrôles : ils ne font pas partie de l'exercice, `make check-etape-XX` joue ce rôle.
