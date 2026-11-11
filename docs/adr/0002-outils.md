# ADR 0002 : choix et épinglage des outils

- **Statut** : accepté
- **Date** : 2026-11-11. Versions relevées ce jour par `git ls-remote` sur les dépôts officiels ; images téléchargées et digests relevés localement.

## Outils retenus

| Besoin | Outil | Version | Pourquoi lui | Alternatives écartées |
|---|---|---|---|---|
| Secrets | Gitleaks | 8.30.1 | Binaire unique, règles par défaut solides, règles maison en TOML, sortie SARIF | TruffleHog (vérifie la validité des secrets, plus lourd) |
| SAST | Semgrep CE | 1.185.0 | Règles lisibles, analyse de teinte pour Flask, règles maison en YAML | CodeQL (gratuit sur dépôt public, mais hors `make`), Bandit (Python seul), Opengrep (fork à suivre) |
| Dépendances, image, SBOM, IaC | Trivy | 0.76.2 | Un seul outil pour quatre usages, exceptions avec expiration native, scan sur archive | OSV-Scanner, Grype + Syft |
| IaC (second avis) | Checkov | 3.4.3 | Contrôles de graphe (`CKV2_*`), exceptions en commentaire dans le code | KICS ; tfsec (fusionné dans Trivy) |
| Policies maison | Conftest (OPA) | 0.71.1 | Rego est aussi le langage des règles personnalisées de Wiz ; s'applique au plan JSON | Politiques Checkov en YAML (plus simples, moins transférables) |
| IaC | Terraform | 1.17.1 | Outil demandé ; verrou S3 natif | OpenTofu (compatible, à évaluer) |
| Workflows | actionlint | 1.7.12 | Détecte erreurs de syntaxe et injections de script | zizmor (audit de sécurité plus poussé, à ajouter) |
| CSPM | Prowler | 5.48.0 | Référence libre, lecture seule, rapports HTML et OCSF | ScoutSuite |

Provider Terraform AWS : 6.72.0, figé par `.terraform.lock.hcl`.

## Actions GitHub, épinglées par SHA de commit

| Action | Version | SHA |
|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `actions/upload-artifact` | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` |
| `actions/download-artifact` | v8.0.2 | `9000827ccba6bdab643e8b6fd33ac0654aef8333` |
| `github/codeql-action/upload-sarif` | v4.39.3 | `33d7b85da1a04171e211befe2c739303b9a4c066` |
| `aws-actions/configure-aws-credentials` | v6.3.0 | `e1253824e5c10ff9df46874f81ed3ec929e19cfd` |

Les digests des images sont dans le `Makefile`.

## Avis de sécurité pris en compte

- **Trivy, mars 2026 (CVE-2026-33634, GHSA-69fq-xp46-6x23).** Une version malveillante de Trivy (v0.69.4) a été publiée et 76 des 77 tags de l'action `trivy-action` ont été redirigés vers un voleur de secrets de CI. L'incident figure au catalogue des vulnérabilités exploitées de la CISA. Conséquences ici : aucune action Trivy n'est utilisée, l'image est épinglée par digest sur une version postérieure, et aucun secret durable n'est présent dans les jobs de scan. Les sources consultées divergent sur la liste exacte des versions touchées : se référer à l'avis GitHub.
- **Checkov.** Plusieurs avis publiés en 2026 sur la branche 3.2.x, dont un durcissement de l'extraction d'archives. La version retenue, 3.4.3, est postérieure. Checkov analyse du contenu non fiable (le code d'une PR) : le faire tourner dans un conteneur sans secret limite l'impact.
- **Gitleaks, Semgrep.** Aucun avis de sécurité trouvé pour 2026 lors de la recherche. À noter côté Semgrep : des fonctions migrent vers l'offre payante, ce qui justifie de surveiller Opengrep.

## Documentation

MkDocs Material 9.8.1. Le projet annonce sa fin de vie au 5 mai 2027, avec Zensical comme successeur compatible avec `mkdocs.yml`. Sans urgence pour un site statique, mais la migration est à prévoir.

## Leçon générale

Un scanner est un programme tiers qui lit du code non fiable, souvent avec des secrets à portée de main. Trois règles en découlent : épingler par empreinte (SHA ou digest), ne donner aucun droit inutile au jeton du job qui scanne, ne jamais exposer de secret durable à ces jobs.

## Limites de cette vérification

Les versions et les digests ont été vérifiés par exécution. Les avis de sécurité viennent d'une recherche web faite le même jour, pas d'une lecture exhaustive des bases d'avis : à refaire avant toute mise à jour.

## Mise à jour

Aucun robot de mise à jour n'est configuré. Monter une version demande de changer le tag **et** le digest dans le `Makefile`, puis de relancer `make demo-good` et `make demo-bad`. En production, Renovate sait faire les deux.
