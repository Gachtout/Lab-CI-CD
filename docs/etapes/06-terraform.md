# Étape 6 : Terraform, format, validation et plan

## Objectif

Décrire une infrastructure AWS en code et obtenir, sur chaque pull request, la liste exacte de ce qui serait créé. Sans compte AWS pour l'instant.

## Le concept, depuis zéro

**Le problème.** Une infrastructure créée à la console n'a ni historique, ni relecture, ni moyen d'être rejouée. Personne ne sait pourquoi un port est ouvert.

**L'idée de Terraform.** On décrit l'état *voulu* dans des fichiers. Terraform compare trois choses :

| Élément | Rôle |
|---|---|
| Le **code** (`*.tf`) | Ce que tu veux |
| L'**état** | Ce que Terraform croit avoir créé |
| La **réalité** (les API AWS) | Ce qui existe vraiment |

`terraform plan` calcule la différence et l'affiche ; `terraform apply` l'exécute. Le plan est l'objet central pour la sécurité : c'est une **prédiction lisible par une machine** de chaque changement. On peut donc le contrôler avant qu'il ne se produise (étape 7).

**Trois contrôles, du moins cher au plus riche :**

1. La vérification de format : le code est-il formaté de façon standard ? Aucun appel réseau.
2. La validation : les références et les types sont-ils cohérents ? Charge les providers, n'appelle pas AWS.
3. Le plan : que va-t-il se passer ? Normalement, interroge AWS.

**Un plan sans AWS.** Quand il n'existe encore aucune ressource et aucune source de données distante, le plan n'a rien à lire chez AWS. Avec trois options `skip_*` du provider et de faux identifiants, il se calcule donc hors ligne. Deux intérêts : le lab se rejoue sans compte, et une PR venant d'un fork peut être planifiée sans qu'on lui confie le moindre identifiant.

## Ce qui t'est fourni

- L'image `TERRAFORM_IMAGE` dans la plomberie.
- Les cibles `tf-fmt`, `tf-validate`, `plan` et `tf-lock`, vides.
- Un dossier `terraform/` vide.

## Énoncé

Livrables :

- Des modules dans `terraform/modules/` et un environnement dans `terraform/envs/dev/`.
- Les cibles `make tf-fmt`, `make tf-validate`, `make plan`, `make tf-lock`.
- Le workflow `.github/workflows/terraform-plan.yml`.

Contraintes :

1. `make tf-fmt` réussit sur ton code et échoue sur un fichier mal formaté.
2. `make tf-validate` réussit sur ton code et échoue sur une référence invalide.
3. `make plan` fonctionne sans aucun identifiant AWS et exporte le plan dans `reports/tfplan.json`.
4. Le plan crée au moins : un VPC, un sous-réseau, un security group, un bucket S3 avec son blocage d'accès public, un rôle IAM.
5. Le plan ne crée aucune ressource payante : ni NAT Gateway, ni instance, ni adresse IP élastique, ni base de données, ni répartiteur de charge, ni clé KMS.
6. Le fichier de verrouillage des providers est commité dans `terraform/envs/dev/`.
7. L'état distant est déclaré dans un backend S3, chiffré, avec le verrou natif (sans table DynamoDB).
8. Le workflow `terraform-plan` se déclenche sur les pull requests, appelle `make tf-fmt`, `make tf-validate` et produit le plan. Aucun de ses jobs ne peut obtenir d'identifiants cloud.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Environnement | `terraform/envs/dev/` (module racine) |
| Cibles `make` | `tf-fmt`, `tf-validate`, `plan`, `tf-lock` |
| Plan exporté | `reports/tfplan.json` (et une version lisible dans `reports/tfplan.txt`) |
| Workflow | `.github/workflows/terraform-plan.yml`, job `plan` |
| Tags | tous les objets taggables portent `Project`, `Environment`, `Owner`, `ManagedBy` (utile à l'étape 7) |

## Critère de réussite

```bash
make check-etape-06
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Sépare ce qui est réutilisable (les modules) de ce qui assemble (l'environnement).
    - Un plan ne lit AWS que s'il a quelque chose à y lire : un état existant ou une source de données distante.

??? tip "Indice 2 : les points qui coincent"
    - Le provider AWS a des options qui désactivent ses vérifications au démarrage ; pilote-les par une variable booléenne.
    - Un backend S3 ne peut pas s'initialiser sans AWS. Terraform sait surcharger un bloc avec un fichier `*_override.tf`.
    - Pour ne rien écrire dans le dépôt, travaille dans une copie à l'intérieur du conteneur, et déporte le dossier de données de Terraform.
    - Les tags communs se déclarent une fois, au niveau du provider.

??? tip "Indice 3 : presque la réponse"
    - Trois options du provider qui sautent ses vérifications, de faux identifiants passés au conteneur par l'environnement, et un backend local écrit dans un fichier de surcharge.
    - Après le plan : une commande l'exporte en JSON, la même sans option JSON l'exporte en texte.
    - Le verrou natif du backend S3 est un booléen ; il existe depuis Terraform 1.10.
    - Le fichier de verrouillage se génère pour plusieurs plateformes avec la sous-commande des providers.
    - Le workflow n'a besoin que de lire le code et, si tu commentes la PR, d'écrire sur les pull requests.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Désaligne une affectation dans un fichier et lance `make tf-fmt`.
2. Référence une sortie de module qui n'existe pas et lance `make tf-validate`.
3. Ouvre le security group à tout Internet et relance les trois commandes. Tout est vert : pourquoi ? Qu'est-ce que ces contrôles ne vérifient pas ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Que compare `terraform plan`, exactement ? Cite les trois éléments.
2. Pourquoi l'état Terraform est-il un fichier sensible ?
3. À quoi sert un verrou d'état ? Que se passe-t-il sans lui ?
4. Pourquoi commiter le fichier de verrouillage des providers ?
5. Pourquoi le plan d'une PR ne doit-il pas avoir d'identifiants cloud ? Qu'y perds-tu ?
6. Quelle différence entre `fmt`, `validate` et `plan` en termes de ce qu'ils détectent ?
7. Pourquoi pas de NAT Gateway dans un lab ? Et en production, que mettrais-tu à la place pour un sous-réseau privé ?

## Côté Wiz, en entreprise

`fmt`, `validate` et `plan` restent des commandes Terraform : Wiz ne les remplace pas. Ce que Wiz ajoute, c'est le scan du code ou du plan produit ici (`wizcli iac scan`). Le fichier de plan JSON de cette étape est donc l'entrée de l'étape suivante, avec Wiz comme avec les outils gratuits.

## Corrigé

À ouvrir seulement une fois `make check-etape-06` vert et les questions travaillées : [`etape-06-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-06-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le corrigé de cette étape garde le cache des providers dans `.cache/` du dépôt ; déplacé à l'étape 8.
- Le module IAM reçoit une limite de permissions à l'étape 10.
