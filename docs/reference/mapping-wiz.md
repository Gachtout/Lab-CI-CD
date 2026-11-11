# Correspondance Wiz ↔ outils gratuits

!!! note "Source et fiabilité"
    La documentation de Wiz n'est pas publique. Les colonnes « Wiz » s'appuient sur des guides d'intégration publics et sur le fonctionnement général du produit. **Vérifie chaque commande et chaque option dans la documentation de ton tenant** : les sous-commandes de `wizcli` ont changé entre versions, et le comportement du code de sortie dépend de la politique attachée.

## Dans le pipeline

| Besoin | Dans ce lab | Cible `make` | Avec Wiz |
|---|---|---|---|
| Secrets dans le code | Gitleaks | `secrets` | `wizcli dir scan` (détection de secrets), scan des dépôts connectés |
| Dépendances vulnérables (SCA) | Trivy fs | `sca` | `wizcli dir scan` |
| Failles du code (SAST) | Semgrep CE | `sast` | Wiz Code ; souvent complété par un SAST dédié |
| Vulnérabilités de l'image | Trivy image | `image-scan` | `wizcli docker scan` |
| Configuration de l'image | Trivy (config d'image) | `image-scan` | `wizcli docker scan`, `wizcli iac scan` sur le Dockerfile |
| Mauvaises configurations IaC | Trivy config, Checkov | `iac` | `wizcli iac scan` |
| Règles maison | Conftest, Rego | `policy` | Règles de configuration cloud personnalisées, en Rego |
| SBOM | Trivy, CycloneDX | `sbom` | Inventaire des composants par workload |
| Seuils de blocage | Variables du `Makefile` | toutes | Politiques de CI/CD, dans la console |
| Exceptions | `.trivyignore.yaml`, `checkov:skip` | `exceptions` | Ignore rules : périmètre, justification, expiration |
| Synthèse sur la PR | `scripts/summary.py` | `summary` | Commentaires de PR par l'intégration de gestion de code |

## Hors du pipeline

| Besoin | Dans ce lab | Avec Wiz |
|---|---|---|
| Posture du compte (CSPM) | Prowler, à la demande | Scan continu sans agent de tous les comptes |
| Corrélation des risques | Aucune | Graphe de sécurité, combinaisons toxiques |
| Exécution (runtime) | Aucune | Capteur d'exécution |
| Lien code ↔ cloud | Aucun | Rapprochement d'une ressource avec le dépôt qui l'a créée |

## Ce qui ne change pas avec Wiz

Ces éléments restent à ta charge, quel que soit l'outil de scan :

- la structure des workflows, les permissions du jeton, l'épinglage des actions (étape 1) ;
- le build reproductible de l'image (étape 2) ;
- `terraform fmt`, `validate`, `plan` (étape 6) ;
- la protection de branche et les statuts requis, qui **appliquent** le verdict (étape 9) ;
- l'authentification du pipeline au cloud par OIDC et le moindre privilège (étape 10).

## Trame d'intégration de Wiz dans un pipeline

Ce que ce lab permet de préparer, dans l'ordre où cela se déroule généralement :

1. Créer un compte de service Wiz limité au scan, stocker son identifiant et son secret dans les secrets de la CI.
2. Ajouter un job par type de scan (répertoire, IaC, image), comme les jobs `sca`, `iac` et `image` d'ici.
3. Démarrer avec des politiques en **mode audit** : le pipeline reste vert, les constats remontent. Mesurer le bruit.
4. Traiter le bruit par des ignore rules justifiées et datées, pas en baissant le seuil.
5. Passer les politiques en **mode blocage**, par périmètre.
6. Rendre le job requis dans la protection de branche. Sans cette étape, rien n'est bloqué.
