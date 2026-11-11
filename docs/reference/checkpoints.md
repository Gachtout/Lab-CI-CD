# Points de contrôle manuels

Certaines actions ne peuvent être faites que par toi : créer le dépôt, régler GitHub, créer le compte AWS. Chaque point de contrôle indique quoi faire, dans quel ordre, et ce qu'il faut observer.

État au moment de la livraison : **tout ce qui tourne en local a été exécuté** (`make demo-good`, `make demo-bad`, actionlint sur les quatre workflows, `terraform validate`, plans hors ligne). **Rien n'a été exécuté sur GitHub ni sur AWS.**

## Point de contrôle 0 : rejouer en local

Docker, `make`, `bash` ; sous Windows, dans WSL2.

```bash
git clone https://github.com/Gachtout/Lab-CI-CD.git && cd Lab-CI-CD
make demo-good
make demo-bad
```

Le premier lancement télécharge environ 3,5 Go d'images. Si Docker Hub répond `429`, ajoute `DOCKERHUB=mirror.gcr.io`.

## Point de contrôle 1 : premier pipeline sur GitHub (étape 1)

Le dépôt doit être **public** : Code Scanning, le secret scanning avec push protection et les rulesets sont gratuits sur les dépôts publics.

1. Onglet **Actions** : le workflow `pr-security` s'est exécuté sur `main` au moment du push. Attendu : tous les jobs verts, `security-gate` vert. Le workflow `deploy` ne fait rien tant que le bootstrap AWS n'est pas fait.
2. Onglet **Security → Code scanning** : les catégories `gitleaks`, `semgrep`, `trivy-sca`, `trivy-image`, `trivy-config`, `checkov` apparaissent, sans alerte ouverte.

Si un job échoue ici, c'est un écart entre l'environnement de construction du lab et les runners GitHub : le journal du job est le premier élément à corriger.

## Point de contrôle 2 : protection de branche (étape 9)

À faire **après** un premier pipeline vert sur `main`, sinon les statuts requis n'existent pas encore.

```bash
gh auth login
scripts/setup-github.sh
```

Puis déroule les trois essais de l'[étape 9](../etapes/09-branch-protection.md) : push direct refusé, PR « bad » bloquée, PR saine fusionnable. Fais les captures listées dans la page [Captures](captures.md).

## Point de contrôle 3 : compte AWS (étape 10)

1. Crée un compte AWS. Active la MFA sur l'utilisateur racine et ne t'en sers plus.
2. Crée un utilisateur administrateur via IAM Identity Center, et configure `aws configure sso`.
3. Déroule le tableau **Bootstrap** de l'[étape 10](../etapes/10-oidc-deploy.md), commande par commande.
4. Confirme l'abonnement au courriel d'alerte de budget.
5. Fusionne une PR qui touche `terraform/`, approuve le déploiement, vérifie, puis lance `destroy`.

Coût attendu : zéro. Les ressources créées (VPC, sous-réseau, security group, bucket vide, rôles IAM, fournisseur OIDC, budget) ne sont pas facturées. Quand tu as fini : workflow `destroy`, puis `terraform destroy` dans `terraform/bootstrap`.

## Point de contrôle 4 : publier la documentation

Sur Cloudflare Pages, *Create application → Pages → Connect to Git*, puis :

| Réglage | Valeur |
|---|---|
| Build command | `pip install -r docs/requirements.txt && mkdocs build` |
| Build output directory | `site` |
| Variable d'environnement | `PYTHON_VERSION` = `3.13` |

En local : `pip install -r docs/requirements.txt && mkdocs serve`.

## Point de contrôle 5 : finir le portfolio

- Ajoute les captures dans `docs/assets/captures/` et décommente les images du README.
- Complète la liste en bas de la page [Leçons apprises](lecons-apprises.md) avec ce que tu as réellement observé.
- Remplace les avertissements « Non exécuté » des étapes 9, 10 et 11 par tes sorties réelles.
