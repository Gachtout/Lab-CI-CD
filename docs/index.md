# Lab DevSecOps, mode exercice

Tu construis une chaîne CI/CD **GitHub Actions + Terraform (AWS free tier)** qui bloque les changements vulnérables. Rien n'est écrit à ta place : chaque étape a un énoncé, des contraintes numérotées et une vérification.

## Comment ça marche

1. Lis la page de l'étape : objectif, concept, énoncé, contrat d'interface.
2. Implémente, puis lance `make check-etape-XX`.
3. Un échec cite la contrainte et l'emplacement, jamais la correction.
4. Trois niveaux d'indices sont repliés dans chaque page.
5. Travaille les questions « Défends ton choix », note tes observations dans le [journal](journal.md).
6. Compare ensuite avec le corrigé.

## Parcours

| # | Étape | À la fin, tu sais |
|---|---|---|
| 1 | [Pipeline minimal](etapes/01-pipeline-minimal.md) | Écrire un workflow, régler les droits du jeton, épingler une action |
| 2 | [Build, tests, Docker](etapes/02-build-test-docker.md) | Construire une image reproductible et non privilégiée |
| 3 | [Secrets](etapes/03-secrets.md) | Bloquer un secret, écrire une règle maison |
| 4 | [SAST et SCA](etapes/04-sast-sca.md) | Distinguer tes failles de celles de tes dépendances, fixer un seuil |
| 5 | [Image](etapes/05-image.md) | Scanner et durcir une image |
| 6 | [Terraform](etapes/06-terraform.md) | Planifier une infrastructure sans compte cloud |
| 7 | [Scan IaC et policies](etapes/07-iac-policies.md) | Écrire et tester une policy Rego |
| 8 | [Quality gates](etapes/08-quality-gates.md) | Transformer des constats en verdict, gérer des exceptions |
| 9 | [Protection de branche](etapes/09-branch-protection.md) | Rendre le verdict impossible à contourner |
| 10 | [OIDC, apply, destroy](etapes/10-oidc-deploy.md) | Déployer sans clé statique, en moindre privilège |
| 11 | [SBOM et Prowler](etapes/11-prowler-sbom.md) | Inventorier une livraison, auditer un compte |

## Références

- [Correspondance Wiz ↔ outils gratuits](reference/mapping-wiz.md)
- [Limites de ces outils face à Wiz](reference/limites.md)
- [Décisions d'architecture du corrigé](adr/0001-architecture.md) : à lire après le parcours, elles en dévoilent la conception.
