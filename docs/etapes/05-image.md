# Étape 5 : scan de l'image Docker

## Objectif

Vérifier ce qui sera réellement exécuté : pas seulement ton code, mais le système d'exploitation et les bibliothèques embarqués dans l'image.

## Le concept, depuis zéro

À l'étape 4, la SCA lisait `requirements.txt` : deux dépendances. L'image, elle, contient une distribution Debian complète, l'interpréteur Python et tout ce que `pip` a tiré. **La surface réelle est celle de l'image, pas celle du dépôt.**

Un scanner d'image ouvre chaque couche, dresse l'inventaire des paquets (base `dpkg` pour l'OS, métadonnées `dist-info` pour Python), puis compare cet inventaire à une base de vulnérabilités. Il lit aussi la configuration de l'image : utilisateur d'exécution, variables d'environnement, historique des commandes.

Deux points contre-intuitifs :

- **Épingler par digest fige aussi les failles.** L'image de base ne bouge plus, donc ses CVE non plus. Il faut appliquer les correctifs au build (`apt-get upgrade`) et monter régulièrement le digest.
- **Un outil d'installation est une dépendance.** `pip` embarque ses propres bibliothèques. Il ne sert plus une fois l'application installée : le retirer supprime ses CVE.

## Ce qu'on fait

- `make image-scan` : exporte l'image en archive (`docker save`), puis la donne à Trivy. Trivy n'a donc **pas besoin du socket Docker**, qui équivaut à un accès root sur la machine.
- Scanners activés : vulnérabilités (OS et Python), secrets dans les couches, mauvaise configuration de l'image.
- Même seuil qu'à l'étape 4 : `HIGH` et `CRITICAL` avec correctif.
- Job `image` dans le workflow.

## Ce que le premier scan a révélé

L'image de l'étape 2 semblait propre : base récente, épinglée, non-root. Le premier scan a pourtant échoué.

```text
== debian 13.7
   zlib1g      1:1.3.dfsg+really1.3.1-1+b1 -> …-1+deb13u1   HIGH CVE-2026-76844
   zlib1g      1:1.3.dfsg+really1.3.1-1+b1 -> …-1+deb13u1   HIGH CVE-2026-85091
== Python
   msgpack     1.1.2  -> 1.2.3    HIGH CVE-2026-114613
   msgpack     1.1.2  -> 1.2.1    HIGH GHSA-6v7p-g79w-8964
   setuptools  70.3.0 -> 78.1.1   HIGH CVE-2025-47273
   urllib3     2.7.0  -> 2.8.0    HIGH CVE-2026-97687
   urllib3     2.7.0  -> 2.8.0    HIGH CVE-2026-97689
```

Aucune de ces bibliothèques Python n'est dans `requirements.txt` : elles sont embarquées par `pip` (`site-packages/pip/_vendor/`). Deux lignes ont été ajoutées au `Dockerfile` :

```dockerfile
RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir -r requirements.txt && pip uninstall --yes pip
```

## Comment vérifier

```bash
make build image-scan
```

```text
│ .cache/image.tar (debian 13.7)                    │   debian   │        0        │    -    │
│ …/site-packages/flask-3.1.3.dist-info/METADATA    │ python-pkg │        0        │    -    │
│ …/site-packages/gunicorn-27.0.0.dist-info/METADATA│ python-pkg │        0        │    -    │
```

## Casse-le volontairement

Remplace `app/Dockerfile` par une version « à l'ancienne » :

```dockerfile
FROM python:3.7-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

Python 3.7 n'accepte pas `gunicorn==27.0.0` : mets `gunicorn==20.1.0` dans `requirements.txt`, puis `make build image-scan`.

```text
Total: 98 (HIGH: 85, CRITICAL: 13)
│ libexpat1  │ CVE-2024-45491 │ CRITICAL │ 2.5.0-1  │ 2.5.0-1+deb12u1  │
│ libssl3    │ CVE-2026-31789 │ CRITICAL │ 3.0.9-1  │ 3.0.19-1~deb12u2 │
│ perl-base  │ CVE-2026-13221 │ CRITICAL │ 5.36.0-7 │ 5.36.0-7+deb12u4 │
…
Failures: 1 (HIGH: 1, CRITICAL: 0)
DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user as argument
make: *** [Makefile:126: image-scan] Error 1
```

98 vulnérabilités système pour un `Dockerfile` de six lignes qui « marche ». Annule avec `git checkout app/`.

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make image-scan` (Trivy sur archive) | `wizcli docker scan --image …` après le build, avant le push au registre |
| Seuil dans le `Makefile` | Politique de vulnérabilités d'image, gérée dans la console |
| Scan au build uniquement | Scan au build **et** scan continu des images déjà déployées, depuis le registre et les workloads |

Le dernier point est la vraie différence : une image verte aujourd'hui aura des CVE demain. Wiz la re-scanne sans nouveau build et sait si elle tourne, sur quoi, et si elle est exposée à Internet. Ce lab ne voit l'image qu'au moment du pipeline.
