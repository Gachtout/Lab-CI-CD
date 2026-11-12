# Étape 5 : scan de l'image Docker

## Objectif

Vérifier ce qui sera réellement exécuté : pas seulement ton code, mais le système d'exploitation et les bibliothèques embarqués dans l'image.

## Le concept, depuis zéro

À l'étape 4, la SCA lisait `requirements.txt` : deux dépendances. L'image, elle, contient une distribution Debian complète, l'interpréteur Python et tout ce que `pip` a tiré. **La surface réelle est celle de l'image, pas celle du dépôt.**

Un scanner d'image ouvre chaque couche, dresse l'inventaire des paquets (base `dpkg` pour l'OS, métadonnées `dist-info` pour Python), puis compare cet inventaire à une base de vulnérabilités. Il lit aussi la configuration de l'image : utilisateur d'exécution, variables d'environnement, historique des commandes.

Deux points contre-intuitifs :

- **Épingler par digest fige aussi les failles.** L'image de base ne bouge plus, donc ses CVE non plus. Il faut appliquer les correctifs au build et monter régulièrement le digest.
- **Un outil d'installation est une dépendance.** `pip` embarque ses propres bibliothèques. Il ne sert plus une fois l'application installée : le retirer supprime ses CVE.

## Ce qui t'est fourni

- La cible `image-scan`, vide.
- Les options de seuil Trivy que tu as écrites à l'étape 4.

## Énoncé

Livrables :

- La cible `make image-scan`.
- Un `app/Dockerfile` qui passe ce scan.
- Un job `image` dans `pr-security.yml`.

Contraintes :

1. `make build image-scan` réussit sur ton image : aucune vulnérabilité `HIGH` ou `CRITICAL` avec correctif, dans le système comme dans les bibliothèques Python.
2. `make image-scan` échoue sur une image construite à partir d'une base en fin de vie.
3. Le scanner n'a pas accès au socket Docker.
4. `make image-scan` échoue sur une image qui s'exécute en root : la configuration de l'image est analysée, pas seulement ses paquets.
5. Le rapport SARIF est écrit dans `reports/trivy-image.sarif`.
6. Le job `image` appelle `make build` puis `make image-scan`.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Cible `make` | `image-scan` |
| Image analysée | celle que désigne `IMAGE` ; `make image-scan IMAGE=x` analyse une image existante sans la reconstruire |
| Rapport | `reports/trivy-image.sarif` |
| Nom du job | `image` |

## Critère de réussite

```bash
make check-etape-05
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Un scanner d'image n'a pas besoin du démon Docker : une image est une archive.
    - Lance d'abord le scan sur ton image de l'étape 2 et lis ce qu'il trouve avant de modifier quoi que ce soit.

??? tip "Indice 2 : les points qui coincent"
    - Docker sait exporter une image dans un fichier ; Trivy sait lire ce fichier. Le dossier de cache de la plomberie est monté dans le conteneur.
    - Les constats viennent de deux endroits : les paquets du système, et des bibliothèques Python qui ne sont pas dans `requirements.txt`. Cherche qui les a apportées.
    - Trivy distingue l'analyse du contenu de l'image et l'analyse de sa configuration.

??? tip "Indice 3 : presque la réponse"
    - Exporte l'image dans le dossier de cache, puis donne ce fichier à Trivy par son option d'entrée.
    - Les paquets du système se mettent à jour au build ; pense à nettoyer les listes du gestionnaire de paquets dans la même couche.
    - L'outil d'installation Python n'est plus utile une fois les dépendances installées.
    - L'analyse de la configuration de l'image s'active par une option distincte de celle qui choisit les scanners de contenu.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Scanne l'image de l'étape 2 avant tout durcissement. Combien de constats, et d'où viennent-ils ?
2. Construis l'image depuis une base Python en fin de vie, sans utilisateur déclaré. Compare les totaux.
3. Monte le socket Docker dans un conteneur et liste les conteneurs de l'hôte. Que peux-tu faire d'autre avec cet accès ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Pourquoi scanner l'image alors que les dépendances ont déjà été scannées ?
2. Pourquoi le socket Docker équivaut-il à un accès root sur la machine ?
3. Une image verte aujourd'hui l'est-elle demain ? Que mets-tu en place ?
4. D'où venaient les vulnérabilités Python absentes de `requirements.txt` ? Qu'en déduis-tu sur les outils de build ?
5. Mettre à jour les paquets au build nuit à la reproductibilité. Comment arbitres-tu ?
6. Quelle différence entre une vulnérabilité de l'image et une mauvaise configuration de l'image ?

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make image-scan` (Trivy sur archive) | `wizcli docker scan --image …` après le build, avant le push au registre |
| Seuil dans le `Makefile` | Politique de vulnérabilités d'image, gérée dans la console |
| Scan au build uniquement | Scan au build **et** scan continu des images déjà déployées, depuis le registre et les workloads |

Le dernier point est la vraie différence : une image verte aujourd'hui aura des CVE demain. Wiz la re-scanne sans nouveau build et sait si elle tourne, sur quoi, et si elle est exposée à Internet. Ce lab ne voit l'image qu'au moment du pipeline.

## Corrigé

À ouvrir seulement une fois `make check-etape-05` vert et les questions travaillées : [`etape-05-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-05-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le corrigé de cette étape garde l'archive de l'image dans `.cache/` du dépôt ; le cache devient partageable (variable `CACHE`) à l'étape 8.
