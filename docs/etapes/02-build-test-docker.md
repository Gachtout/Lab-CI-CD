# Étape 2 : build, tests et image Docker

## Objectif

Disposer d'une application testée automatiquement et d'une image Docker reproductible. C'est la matière que les étapes suivantes vont scanner.

## Le concept, depuis zéro

**Pourquoi des tests dans une chaîne de sécurité ?** Parce qu'un correctif de sécurité est un changement comme un autre : sans tests, on ne sait pas s'il casse l'application. Les tests servent aussi de preuve. Ici, un test vérifie qu'une charge d'injection SQL ne renvoie rien.

**Qu'est-ce qu'une image Docker ?** Une archive de couches de fichiers, plus quelques métadonnées (utilisateur, commande de démarrage). Chaque instruction du `Dockerfile` ajoute une couche. Deux conséquences pour la sécurité :

- Tout ce qui entre dans une couche y reste, même si une instruction ultérieure le supprime. Un secret copié puis effacé est toujours lisible dans l'image.
- L'image embarque un système d'exploitation complet. Ses paquets ont des vulnérabilités que ton code n'a jamais appelées, mais qu'un attaquant peut atteindre.

**Tag ou digest ?** `python:3.13-slim` est un tag : une étiquette que l'éditeur déplace à chaque reconstruction. Le digest `sha256:…` est l'empreinte du contenu. Écrire les deux (`tag@digest`) donne la lisibilité du premier et l'immuabilité du second.

## Ce qui t'est fourni

- L'application (`app/app.py`), ses tests (`app/tests/`) et ses dépendances (`app/requirements*.txt`).
- Les variables `PYTHON_IMAGE`, `IMAGE` et `DOCKER_BUILD` de la plomberie.
- Les cibles `test` et `build`, vides.

## Énoncé

Livrables :

- `app/Dockerfile` (et `app/.dockerignore`).
- Les cibles `make test` et `make build`.
- Un job `build-test` dans `pr-security.yml`.

Contraintes :

1. L'image de base est épinglée par digest.
2. Le conteneur ne s'exécute pas en root : un utilisateur sans privilège est déclaré, et c'est lui qui lance l'application.
3. L'image déclare un contrôle de santé.
4. L'installation des dépendances ne laisse pas le cache de `pip` dans l'image.
5. `make test` lance les tests unitaires dans l'image Python de la plomberie, et échoue si un test échoue.
6. `make build` construit l'image dont le nom est donné par la variable `IMAGE`.
7. Le job `build-test` appelle `make test` puis `make build`.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Dockerfile | `app/Dockerfile`, contexte de build `app/` |
| Cibles `make` | `test`, `build` |
| Nom de l'image | variable `IMAGE` (`make build IMAGE=mon-nom:tag`) |
| Nom du job | `build-test` |
| Port et serveur | l'application écoute sur le port 8000, servie par gunicorn |

## Critère de réussite

```bash
make check-etape-02
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Un Dockerfile de production répond à trois questions : d'où je pars, qu'est-ce que j'installe, qui exécute quoi.
    - Les tests n'ont pas besoin de l'image de l'application : ils ont besoin d'un interpréteur et des dépendances.

??? tip "Indice 2 : les points qui coincent"
    - Le digest d'une image s'obtient après un `docker pull`, avec `docker inspect` (champ des digests du dépôt).
    - Un utilisateur se crée dans l'image puis s'active par une instruction dédiée ; préfère un identifiant numérique.
    - Pour `make test`, un environnement virtuel créé dans `/tmp` du conteneur évite d'écrire dans le dépôt monté.
    - Regarde ce que `.dockerignore` permet de ne pas envoyer au build : les tests, par exemple.

??? tip "Indice 3 : presque la réponse"
    - La référence d'image s'écrit avec le tag suivi de l'arobase et du digest.
    - Le contrôle de santé peut interroger la route `/health` avec la bibliothèque standard de Python, sans rien installer.
    - `pip` a une option qui désactive son cache.
    - `make test` : une commande `sh -c` qui crée l'environnement virtuel, installe les deux fichiers de dépendances, puis lance pytest sur `tests`.
    - `make build` : la variable `DOCKER_BUILD`, l'option de nommage avec `$(IMAGE)`, le dossier `app`.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Remplace la requête paramétrée de `app/app.py` par une concaténation de chaînes et relance `make test`. Quel test échoue, et que prouve-t-il ?
2. Retire l'utilisateur non privilégié, reconstruis, puis lance `id` dans le conteneur.
3. Remplace le digest par un tag seul. Le build marche-t-il encore ? Qu'as-tu perdu ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Quelle différence entre un tag et un digest ? Lequel peut changer sans que tu le saches ?
2. Pourquoi un conteneur en root est-il un problème, alors qu'il est « isolé » ?
3. Un secret copié dans une couche puis supprimé dans la suivante est-il encore dans l'image ? Pourquoi ?
4. Pourquoi tester dans la même image Python que celle de production ?
5. À quoi sert un contrôle de santé pour un orchestrateur ?
6. Épingler par digest fige aussi les vulnérabilités de l'image de base. Comment gères-tu cela dans la durée ?

## Côté Wiz, en entreprise

Wiz ne teste pas ton application et ne construit pas ton image : ces deux jobs restent à la charge de l'équipe. En revanche, l'image produite ici est exactement ce que `wizcli` scanne ensuite. Un build non reproductible (tag mobile, dépendances non figées) rend les résultats de scan instables d'un jour à l'autre, quel que soit le scanner.

## Corrigé

À ouvrir seulement une fois `make check-etape-02` vert et les questions travaillées : [`etape-02-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-02-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le Dockerfile du corrigé de cette étape n'est pas encore durci : la mise à jour des paquets et le retrait de `pip` arrivent à l'étape 5.
