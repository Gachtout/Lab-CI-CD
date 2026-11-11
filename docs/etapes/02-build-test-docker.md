# Étape 2 : build, tests et image Docker

## Objectif

Disposer d'une application testée automatiquement et d'une image Docker reproductible. C'est la matière que les étapes suivantes vont scanner.

## Le concept, depuis zéro

**Pourquoi des tests dans une chaîne de sécurité ?** Parce qu'un correctif de sécurité est un changement comme un autre : sans tests, on ne sait pas s'il casse l'application. Les tests servent aussi de preuve. Ici, un test vérifie qu'une charge d'injection SQL ne renvoie rien.

**Qu'est-ce qu'une image Docker ?** Une archive de couches de fichiers, plus quelques métadonnées (utilisateur, commande de démarrage). Chaque instruction du `Dockerfile` ajoute une couche. Deux conséquences pour la sécurité :

- Tout ce qui entre dans une couche y reste, même si une instruction ultérieure le supprime. Un secret copié puis effacé est toujours lisible dans l'image.
- L'image embarque un système d'exploitation complet. Ses paquets ont des vulnérabilités que ton code n'a jamais appelées, mais qu'un attaquant peut atteindre.

**Tag ou digest ?** `python:3.13-slim` est un tag : une étiquette que l'éditeur déplace à chaque reconstruction. Le digest `sha256:…` est l'empreinte du contenu. Écrire les deux (`tag@digest`) donne la lisibilité du premier et l'immuabilité du second.

## Ce qu'on fait

- `app/app.py` : une API Flask à deux routes, `/health` et `/users`, sur une base SQLite.
- `app/tests/` : trois tests pytest.
- `app/Dockerfile` : image de base par digest, dépendances à version fixe, utilisateur non privilégié (UID 10001), `HEALTHCHECK`.
- `make test` et `make build`, appelés par un nouveau job `build-test`.

Les tests tournent dans la même image Python que celle de production. On ne teste pas avec une version et on ne livre pas avec une autre.

## Comment vérifier

```bash
make test
```

```text
...                                                                      [100%]
3 passed in 0.13s
```

```bash
make build
docker run --rm -d --name lab -p 127.0.0.1:8000:8000 devsecops-lab-app:local
curl "http://127.0.0.1:8000/users?name=alice"
docker exec lab id
docker rm -f lab
```

```text
{"result":[{"id":1,"name":"alice","role":"admin"}]}
uid=10001(appuser) gid=999(appuser) groups=999(appuser)
```

Le processus tourne bien sous un compte sans privilège.

## Casse-le volontairement

Dans `app/app.py`, remplace la requête paramétrée par une concaténation :

```python
rows = con.execute("SELECT id, name, role FROM users WHERE name = '%s'" % name).fetchall()
```

Relance `make test` : `test_injection_sql_sans_effet` échoue, car la charge `x' OR '1'='1` renvoie maintenant tous les utilisateurs. Tu viens de prouver la faille par un test. Annule avec `git checkout app/app.py`.

À retenir : ce test n'existe que parce que quelqu'un a pensé à l'écrire. L'étape 4 ajoute un outil (SAST) qui trouve ce défaut sans qu'on le lui ait décrit.

## Côté Wiz, en entreprise

Wiz ne teste pas ton application et ne construit pas ton image : ces deux jobs restent à la charge de l'équipe. En revanche, l'image produite ici est exactement ce que `wizcli` scanne ensuite. Un build non reproductible (tag mobile, dépendances non figées) rend les résultats de scan instables d'un jour à l'autre, quel que soit le scanner.
