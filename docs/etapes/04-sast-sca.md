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

## Ce qu'on fait

- `.semgrep/regles-maison.yml` : deux règles internes (debug Flask en dur, secret de configuration en dur), en plus des jeux communautaires `p/python` et `p/flask`.
- `make sast` : bloque sur la sévérité `ERROR`.
- `make sca` : bloque sur `HIGH` et `CRITICAL` ayant un correctif.
- Jobs `sast` et `sca`, chacun avec publication SARIF.

## Comment vérifier

```bash
make sast && make sca
```

```text
┌──────────────────┬──────┬─────────────────┐
│      Target      │ Type │ Vulnerabilities │
├──────────────────┼──────┼─────────────────┤
│ requirements.txt │ pip  │        0        │
└──────────────────┴──────┴─────────────────┘
```

`make sast` n'affiche rien quand il n'y a aucun résultat.

## Casse-le volontairement

### SAST

Dans `app/app.py`, remets la concaténation SQL de l'étape 2 et ajoute sous la ligne `API_TOKEN` :

```python
app.config["API_TOKEN"] = "jeton-en-dur-a-remplacer"
app.config["DEBUG"] = True
```

```text
┌─────────────────┐
│ 3 Code Findings │
└─────────────────┘
    app/app.py
   ❯❯❱ semgrep.interdit-secret-en-dur
          ❰❰ Blocking ❱❱
           33┆ app.config["API_TOKEN"] = "jeton-en-dur-a-remplacer"
   ❯❯❱ semgrep.interdit-flask-debug
          ❰❰ Blocking ❱❱
           34┆ app.config["DEBUG"] = True
   ❯❯❱ python.flask.security.injection.tainted-sql-string.tainted-sql-string
          ❰❰ Blocking ❱❱
           45┆ rows = con.execute("SELECT id, name, role FROM users WHERE name = '%s'" % name).fetchall()
make: *** [Makefile:106: sast] Error 1
```

Observe que `jeton-en-dur-a-remplacer` n'a pas été vu par Gitleaks à l'étape 3 (ni format, ni entropie). C'est la règle Semgrep maison qui l'attrape, parce qu'elle regarde la **structure** du code, pas la valeur. Les deux outils se complètent.

### SCA

Remplace le contenu de `app/requirements.txt` par :

```text
flask==2.2.2
werkzeug==2.2.2
gunicorn==27.0.0
```

```text
Total: 3 (HIGH: 3, CRITICAL: 0)
│ flask    │ CVE-2023-30861 │ HIGH │ fixed │ 2.2.2 │ 2.3.2, 2.2.5 │
│ werkzeug │ CVE-2023-25577 │      │       │       │ 2.2.3        │
│          │ CVE-2024-34069 │      │       │       │ 3.0.3        │
make: *** [Makefile:111: sca] Error 1
```

La colonne *Fixed Version* donne la correction. Annule avec `git checkout app/`.

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make sca` (Trivy fs) | `wizcli dir scan` : vulnérabilités des dépendances du répertoire |
| `make sast` (Semgrep) | Wiz Code propose une analyse SAST ; beaucoup d'entreprises gardent en parallèle un SAST dédié |
| Seuil `HIGH,CRITICAL` avec correctif | Politique de vulnérabilités : sévérité minimale, « fix available », délai de grâce |

Vérifie la syntaxe exacte de `wizcli` dans la documentation de ton tenant : les sous-commandes ont changé entre versions.
