# Étape 11 (optionnelle) : SBOM et audit du compte avec Prowler

## Objectif

Sortir du pipeline : savoir ce qui a été livré (SBOM) et contrôler ce qui existe réellement dans le compte cloud (CSPM).

## Le concept, depuis zéro

Tous les contrôles précédents portent sur une **intention** : du code, un plan, une image au moment du build. Deux questions restent sans réponse.

**« Une nouvelle CVE sort demain : suis-je concerné ? »** Le pipeline ne tourne que lorsqu'on pousse du code. Un **SBOM** (*Software Bill of Materials*) est l'inventaire des composants d'une image : nom, version, identifiant normalisé. Conservé à chaque livraison, il permet de répondre plus tard, sans reconstruire ni même posséder l'image : on compare l'inventaire à la base de vulnérabilités du jour.

**« Ce qui tourne correspond-il à ce qui a été validé ? »** Rien ne le garantit : une modification à la console, une ressource créée hors Terraform, un compte hérité. Un outil de **CSPM** (*Cloud Security Posture Management*) interroge les API du fournisseur et évalue la configuration réelle. C'est le cœur historique de Wiz.

| | Scan IaC (étape 7) | CSPM (cette étape) |
|---|---|---|
| Entrée | Le code ou le plan | Le compte réel, par ses API |
| Moment | Avant le déploiement | Après, en continu |
| Voit ce qui est créé à la main | Non | Oui |
| Peut bloquer | Oui | Non : il constate |

## Ce qu'on fait

- `make sbom` : inventaire CycloneDX de l'image, dans `reports/sbom.cdx.json`.
- `make sbom-scan` : recherche de vulnérabilités à partir du seul SBOM.
- Job `sbom` : sur `main`, le SBOM est conservé 90 jours en artifact, nommé d'après le commit.
- `make prowler` : audit du compte AWS en lecture seule, constats `critical` et `high` en échec, rapports HTML, CSV et OCSF dans `reports/prowler/`.

## Comment vérifier

```bash
make build sbom
```

```text
SBOM écrit dans reports/sbom.cdx.json
format CycloneDX 1.7 | composants 96
   openssl  3.5.7-1~deb13u3   pkg:deb/debian/openssl@3.5.7-1~deb13u3?arch=amd64…
   gunicorn 27.0.0            pkg:pypi/gunicorn@27.0.0
```

96 composants pour une application qui en déclare deux. Le champ `purl` est l'identifiant universel que les bases de vulnérabilités savent lire.

```bash
make sbom-scan
```

```text
│ reports/sbom.cdx.json (debian 13.7) │   debian   │        0        │
```

Même verdict que le scan d'image, obtenu sans l'image.

### Prowler

!!! warning "Non exécuté par l'auteur du lab"
    La commande et ses options ont été vérifiées contre l'aide de Prowler 5.48.0, pas contre un compte AWS.

Avec des identifiants en lecture seule dans ton terminal (par exemple la politique gérée `SecurityAudit`) :

```bash
AWS_REGION=eu-west-3 make prowler
```

Ouvre ensuite le rapport HTML de `reports/prowler/`. Sur un compte neuf, attends-toi à des constats qui n'ont rien à voir avec ce lab : MFA du compte racine, CloudTrail, politique de mots de passe. C'est le but : le CSPM regarde tout le compte, pas seulement ce que Terraform a créé.

## Casse-le volontairement

- **Dérive.** Après un `apply`, crée à la console un security group ouvert en SSH à `0.0.0.0/0` dans le VPC du lab. Aucun contrôle du pipeline ne le voit : il n'est pas dans le code. Relance `make prowler` : il apparaît. Relance le workflow `deploy` : Terraform ne le signale pas non plus, car il ne gère pas cette ressource. Supprime-la.
- **SBOM dans le temps.** Garde le `sbom.cdx.json` d'aujourd'hui et relance `make sbom-scan` dans quelques semaines : des vulnérabilités apparaîtront sans que l'image ait changé.

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make prowler`, lancé à la demande | Scan continu de tous les comptes par connecteur, sans agent |
| Une liste de constats par ressource | Un **graphe** : la ressource, son exposition réseau, ses identités, ses données, ses vulnérabilités |
| SBOM en artifact | Inventaire des composants de chaque workload, interrogeable (« où tourne cette bibliothèque ? ») |
| Aucun lien entre le code et le compte | Rapprochement d'une ressource cloud avec le dépôt et la ligne de code qui l'ont créée |

C'est ici que l'écart avec les outils gratuits est le plus grand. Voir la page [Limites](../reference/limites.md).
