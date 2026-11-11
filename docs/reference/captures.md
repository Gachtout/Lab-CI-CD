# Captures d'écran à réaliser

À déposer dans `docs/assets/captures/`. Format PNG, largeur 1 600 px environ, thème clair. Masque ton identifiant de compte AWS (12 chiffres) et toute adresse de courriel.

## Démo rouge → vert (prioritaires pour le README)

| Fichier | Ce qu'elle doit montrer |
|---|---|
| `01-demo-local-bad.png` | Terminal : fin de `make demo-bad`, la synthèse avec les huit lignes `BLOQUE` |
| `02-demo-local-good.png` | Terminal : fin de `make demo-good`, neuf lignes `PASSE` |
| `03-pr-bad-checks.png` | PR « bad » : liste des checks, `security-gate` et `plan` en rouge, bouton *Merge* désactivé |
| `04-pr-bad-commentaire.png` | PR « bad » : le commentaire de synthèse avec le tableau des contrôles bloquants |
| `05-pr-bad-plan.png` | PR « bad » : le commentaire du plan avec les lignes `FAIL` `S3-01` et `NET-01` |
| `06-pr-fix-checks.png` | PR saine : tous les checks verts, bouton *Merge* actif |
| `demo.gif` | Enregistrement de 20 à 30 secondes : `make demo-bad` puis `make demo-good` (par exemple avec `asciinema` et `agg`) |

## Détail des constats bloquants

| Fichier | Ce qu'elle doit montrer |
|---|---|
| `07-job-secrets.png` | Journal du job `secrets` : le constat `lab-fake-token`, fichier et ligne |
| `08-job-sast.png` | Journal du job `sast` : les trois constats *Blocking* |
| `09-job-image.png` | Journal du job `image` : le total des CVE et le constat `DS-0002` (root) |
| `10-job-iac.png` | Journal du job `iac` : les constats S3 de Trivy et de Checkov |
| `11-code-scanning.png` | *Security → Code scanning* : les alertes de la PR « bad », filtrées par outil |

## Blocage côté serveur

| Fichier | Ce qu'elle doit montrer |
|---|---|
| `12-push-direct-refuse.png` | Terminal : `git push origin main` refusé par le ruleset |
| `13-ruleset.png` | *Settings → Rules* : le ruleset `main-protegee`, statuts requis visibles, liste de contournement vide |
| `14-push-protection.png` | Terminal ou interface : un push refusé par la push protection (si tu obtiens le blocage) |
| `15-hook-local.png` | Terminal : le hook pre-commit qui refuse le commit, puis `--no-verify` qui passe |

## Déploiement AWS

| Fichier | Ce qu'elle doit montrer |
|---|---|
| `16-deploy-attente.png` | Workflow `deploy` : job `plan-aws` vert, job `apply` en attente d'approbation |
| `17-deploy-plan.png` | Résumé de l'exécution : le plan Terraform à approuver |
| `18-deploy-apply.png` | Job `apply` vert, ligne `Apply complete!` |
| `19-cloudtrail-oidc.png` | CloudTrail : événement `AssumeRoleWithWebIdentity`, champ `sub` visible, compte masqué |
| `20-secrets-vides.png` | *Settings → Secrets and variables → Actions* : aucun secret, cinq variables |
| `21-destroy.png` | Workflow `destroy` : confirmation saisie, job vert, `Destroy complete!` |
| `22-prowler.png` | Rapport HTML de Prowler : vue d'ensemble des constats |
