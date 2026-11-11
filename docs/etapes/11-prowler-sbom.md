# Étape 11 (optionnelle) : SBOM et audit du compte avec Prowler

!!! note "Ce qui est vérifié"
    `make check-etape-11` exécute réellement `make sbom` et `make sbom-scan`. Il **n'exécute pas** `make prowler` : il lit seulement la commande que la cible lancerait. L'audit du compte est à lancer toi-même, avec des identifiants en lecture seule.

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

## Ce qui t'est fourni

- La cible d'export d'image que tu as écrite à l'étape 5.
- Les cibles `sbom`, `sbom-scan`, `prowler`, vides.

## Énoncé

Livrables :

- Les cibles `make sbom`, `make sbom-scan`, `make prowler`, et la variable `PROWLER_IMAGE`.
- Un job `sbom` dans `pr-security.yml`.

Contraintes :

1. `make sbom` produit l'inventaire de l'image au format CycloneDX dans `reports/sbom.cdx.json`.
2. `make sbom-scan` cherche les vulnérabilités à partir de l'inventaire seul, avec le même seuil que les autres contrôles : il réussit sur ton image et échoue sur l'inventaire d'une image vulnérable.
3. L'image de Prowler est épinglée par digest.
4. Le job `sbom` ne s'exécute pas sur les pull requests, appelle `make sbom`, et conserve l'inventaire au moins 30 jours.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Cibles `make` | `sbom`, `sbom-scan`, `prowler` |
| Inventaire | `reports/sbom.cdx.json` |
| Image analysée | celle que désigne `IMAGE` |
| Variable d'image | `PROWLER_IMAGE` |
| Nom du job | `sbom` |
| Rapports Prowler | `reports/prowler/` |

## Critère de réussite

```bash
make check-etape-11
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Trivy sait produire un inventaire, et sait aussi en lire un.
    - Prowler est un outil en ligne de commande, distribué en image : commence par son aide.

??? tip "Indice 2 : les points qui coincent"
    - Le format de sortie de Trivy se choisit par une option ; CycloneDX en fait partie.
    - Le digest d'une image se relève après l'avoir téléchargée, comme à l'étape 2.
    - Une condition de job peut porter sur le nom de l'événement déclencheur.

??? tip "Indice 3 : presque la réponse"
    - `make sbom` réutilise l'archive exportée à l'étape 5 et change seulement le format de sortie.
    - `make sbom-scan` : la sous-commande de Trivy dédiée aux inventaires, suivie de tes options de seuil.
    - Pour Prowler : transmets les identifiants AWS par l'environnement, limite la région et les sévérités, et monte un dossier de sortie accessible en écriture à l'utilisateur du conteneur.
    - L'artifact du job porte le SHA du commit dans son nom, pour retrouver l'inventaire d'une livraison.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Compte les composants de l'inventaire. Combien en déclares-tu dans `requirements.txt` ?
2. Garde l'inventaire d'aujourd'hui et relance `make sbom-scan` dans quelques semaines.
3. Après un apply, crée à la console un security group ouvert en SSH. Quel contrôle du pipeline le voit ? Et Prowler ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. À quoi sert un SBOM le jour où une nouvelle vulnérabilité critique est publiée ?
2. Quelle différence entre scan IaC et CSPM ? Lequel peut bloquer ?
3. Pourquoi le pipeline ne voit-il pas une ressource créée à la console ?
4. Quels droits donnes-tu à un outil d'audit de compte, et pourquoi pas plus ?
5. Qu'apporte un graphe de sécurité qu'une liste de constats n'apporte pas ?

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make prowler`, lancé à la demande | Scan continu de tous les comptes par connecteur, sans agent |
| Une liste de constats par ressource | Un **graphe** : la ressource, son exposition réseau, ses identités, ses données, ses vulnérabilités |
| SBOM en artifact | Inventaire des composants de chaque workload, interrogeable (« où tourne cette bibliothèque ? ») |
| Aucun lien entre le code et le compte | Rapprochement d'une ressource cloud avec le dépôt et la ligne de code qui l'ont créée |

C'est ici que l'écart avec les outils gratuits est le plus grand. Voir la page [Limites](../reference/limites.md).

## Corrigé

À ouvrir seulement une fois `make check-etape-11` vert et les questions travaillées : [`etape-11-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-11-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Aucune.
