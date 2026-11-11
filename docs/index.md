# Lab DevSecOps

Une chaîne CI/CD **GitHub Actions + Terraform (AWS free tier)** qui bloque les changements vulnérables : secrets, code, dépendances, image Docker et infrastructure. Les outils sont gratuits et reproduisent ce que fait Wiz CLI dans un pipeline.

!!! warning "Dépôt volontairement vulnérable à la demande"
    La branche `main` est saine. Le script `scripts/demo.sh bad` y injecte des failles **factices et documentées** pour démontrer le blocage. Les secrets utilisés sont manifestement faux.

## Parcours

Chaque étape correspond à un commit et suit le même plan : objectif, concept depuis zéro, ce qu'on fait, comment vérifier, « casse-le volontairement », équivalent côté Wiz.

| # | Étape | Ce que tu sais faire à la fin |
|---|---|---|
| 1 | [Pipeline minimal](etapes/01-pipeline-minimal.md) | Lire et écrire un workflow, expliquer events, jobs, runners, artifacts |
| 2 | [Build, tests, Docker](etapes/02-build-test-docker.md) | Tester et construire une image de façon reproductible |
| 3 | [Secrets](etapes/03-secrets.md) | Bloquer un secret avant qu'il n'atteigne `main` |
| 4 | [SAST et SCA](etapes/04-sast-sca.md) | Distinguer faille dans ton code et faille dans tes dépendances |
| 5 | [Image](etapes/05-image.md) | Scanner une image et produire un SBOM |
| 6 | [Terraform](etapes/06-terraform.md) | `fmt`, `validate`, `plan` sans compte AWS |
| 7 | [Scan IaC et policies](etapes/07-iac-policies.md) | Écrire une policy Rego et la tester |
| 8 | [Quality gates](etapes/08-quality-gates.md) | Fixer des seuils et gérer des exceptions datées |
| 9 | [Protection de branche](etapes/09-branch-protection.md) | Rendre le blocage impossible à contourner |
| 10 | [OIDC, apply, destroy](etapes/10-oidc-deploy.md) | Déployer sur AWS sans aucune clé statique |
| 11 | [Prowler et SBOM](etapes/11-prowler-sbom.md) | Contrôler ce qui tourne réellement |

## Rejouer la démo en local

Prérequis : Docker, `make`, `bash`. Aucun compte AWS.

```bash
make demo-good   # la branche saine : tout est vert
make demo-bad    # les failles injectées : chaque contrôle bloque
```

## Pour aller plus loin

- [Correspondance Wiz ↔ outils gratuits](reference/mapping-wiz.md)
- [Limites de ce lab face à Wiz](reference/limites.md)
- [Points de contrôle manuels](reference/checkpoints.md)
- [Décisions d'architecture (ADR)](adr/0001-architecture.md)
