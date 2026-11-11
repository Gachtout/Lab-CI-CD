# Étape 8 : quality gates, exceptions et démo rouge / vert

## Objectif

Transformer une collection de scanners en une **décision** : ce changement peut-il être fusionné, oui ou non ? Et prévoir la sortie de secours légitime : l'exception tracée.

## Le concept, depuis zéro

Un scanner produit des constats. Un constat ne bloque rien tant qu'on n'a pas répondu à trois questions.

1. **Quel seuil ?** Tout bloquer rend l'outil insupportable : les équipes le désactivent. Ne rien bloquer le rend décoratif. Un seuil utile bloque ce qui est **grave et corrigeable**.
2. **Par quel mécanisme ?** Le code de sortie. Un gate est une commande qui renvoie `0` ou autre chose, rien de plus.
3. **Que fait-on des cas légitimes ?** Il y en a toujours. Sans procédure d'exception, les gens contournent le contrôle en entier. Une exception saine a un **périmètre** (quelle règle, quelle ressource), une **justification** et une **date de fin**. Sans date, elle devient permanente et plus personne ne sait pourquoi elle existe.

## Les seuils de ce lab

| Contrôle | Bloque si… | Réglage |
|---|---|---|
| Secrets | Un secret est trouvé, toujours | Gitleaks, aucun seuil |
| SAST | Constat de sévérité `ERROR` | `SEMGREP_SEVERITY` dans le `Makefile` |
| Dépendances, image | `HIGH` ou `CRITICAL` **avec correctif disponible** | `TRIVY_SEVERITY`, `--ignore-unfixed` |
| Configuration de l'image, IaC (Trivy) | `HIGH` ou `CRITICAL` | `TRIVY_SEVERITY` |
| IaC (Checkov) | Tout contrôle en échec non écarté | `.checkov.yaml` |
| Policies maison | Toute règle `deny` | `policies/*.rego` |
| Exceptions | Une exception sans date, sans justification, ou expirée | `scripts/check-exceptions.sh` |

Les rapports SARIF envoyés à Code Scanning utilisent le même filtre que le gate : ce qui est affiché est ce qui bloque.

## Les exceptions

Deux niveaux, comme dans un outil commercial.

**Écarter une règle pour tout le dépôt** (elle ne s'applique pas au contexte) : `.checkov.yaml`.

```yaml
skip-check:
  - CKV_AWS_144 # réplication S3 inter-régions : pas de besoin de continuité pour ce lab
```

**Accepter un constat sur une ressource précise**, avec une date de fin : en commentaire dans le code pour Checkov, dans `.trivyignore.yaml` pour Trivy.

```hcl
#checkov:skip=CKV_AWS_145:SSE-S3 accepté pour le lab, une clé KMS est payante - expire le 2027-05-31
```

```yaml
misconfigurations:
  - id: AWS-0132
    paths: [terraform/modules/s3/main.tf]
    expired_at: 2027-05-31
    statement: Chiffrement SSE-S3 accepté pour ce lab…
```

Trivy applique `expired_at` lui-même. Checkov n'a pas de notion d'expiration : `make exceptions` la vérifie.

## Le job `security-gate`

Le workflow a maintenant neuf jobs. Exiger neuf statuts dans la protection de branche serait fragile : chaque renommage casserait la règle. Un job final, `security-gate`, dépend de tous les autres et échoue si l'un d'eux n'est pas en `success`. Il publie aussi la synthèse en commentaire de PR.

```yaml
security-gate:
  if: always()                       # s'exécute même si un job précédent a échoué
  needs: [workflow-lint, build-test, secrets, sast, sca, image, iac, exceptions]
```

Sans `if: always()`, un job dont un prérequis échoue est **sauté**, et un statut sauté n'est pas un échec aux yeux de la protection de branche. C'est pour cela que le script traite tout résultat autre que `success` comme bloquant.

## Comment vérifier : la démo

```bash
make demo-good
```

```text
==> Synthèse
  PASSE  tests
  PASSE  secrets
  PASSE  sast
  PASSE  sca
  PASSE  image
  PASSE  iac-trivy
  PASSE  iac-checkov
  PASSE  policy
  PASSE  exceptions
Démo good : tous les contrôles passent, la fusion serait autorisée.
```

```bash
make demo-bad
```

Le script copie le dépôt, y applique `demo/bad.patch` (injection SQL, secret en dur, dépendances vulnérables, image en fin de vie et en root, security group ouvert, bucket public) et ajoute un secret factice.

```text
==> Synthèse
  BLOQUE tests
  BLOQUE secrets
  BLOQUE sast
  BLOQUE sca
  BLOQUE image
  BLOQUE iac-trivy
  BLOQUE iac-checkov
  BLOQUE policy
  PASSE  exceptions
==> Vérification de la démo
  attendu BLOQUE, obtenu BLOQUE : tests
  …
Démo bad : chaque faille injectée est bloquée, la fusion serait refusée.
```

Le détail de chaque constat bloquant est dans `reports/demo-bad/logs/`. `make demo-bad` renvoie `0` quand tout est bloqué comme attendu : c'est un **test des contrôles eux-mêmes**, rejoué dans la CI par le job `gates-selftest`. Un gate qui cesserait de détecter sa faille de référence ferait échouer ce job.

Avec les caches chauds, chaque démo prend une trentaine de secondes. Le premier lancement télécharge les images et la base de vulnérabilités : compte plusieurs minutes.

## Casse-le volontairement

### Une exception qui expire

```bash
TODAY=2027-06-01 make exceptions
```

```text
ERREUR  terraform/modules/s3/main.tf:4 : CKV_AWS_145 a expiré le 2027-05-31
ERREUR  .trivyignore.yaml : une exception a expiré le 2027-05-31
```

Dans `.trivyignore.yaml`, mets `expired_at: 2026-01-01`, puis `make iac-trivy` : le constat réapparaît.

```text
Failures: 1 (HIGH: 1, CRITICAL: 0)
AWS-0132 (HIGH): Bucket does not encrypt data with a customer managed key.
```

### Une exception sans date

Retire ` - expire le 2027-05-31` d'un commentaire `checkov:skip`, puis `make exceptions`.

```text
ERREUR  terraform/modules/vpc/main.tf:5 : exception sans justification ou sans date (format : ID:raison - expire le AAAA-MM-JJ)
```

### Un seuil trop laxiste

Remplace `app/requirements.txt` par les versions vulnérables de l'étape 4, puis compare :

```bash
make sca                           # bloque : 3 CVE HIGH
make sca TRIVY_SEVERITY=CRITICAL   # passe : aucune n'est CRITICAL
```

Les mêmes dépendances, le même scanner, deux verdicts opposés. Le seuil est une décision de risque, pas un détail technique. Annule avec `git checkout app/`.

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| Seuils dans le `Makefile` | **Politiques de CI/CD**, définies dans la console et attachées à un projet. `wizcli` les télécharge à chaque scan : le seuil ne vit pas dans le dépôt |
| Code de sortie de `make` | Code de sortie de `wizcli` : non nul si la politique est en mode blocage et qu'elle est violée |
| Mode « rapport seul » | Politique en mode audit : le pipeline reste vert, les constats remontent. Utile pour déployer sans tout casser le premier jour |
| `.trivyignore.yaml`, `checkov:skip` | **Ignore rules** : périmètre, justification, expiration, le tout tracé et soumis à des droits |
| `security-gate` | Inchangé : le job qui appelle `wizcli` devient un statut requis |

Différence d'organisation importante : avec Wiz, c'est l'équipe sécurité qui tient les seuils, pas le développeur qui édite un fichier dans sa propre PR. Dans ce lab, une PR peut modifier le `Makefile` pour baisser un seuil. L'étape 9 traite ce point avec les fichiers protégés (`CODEOWNERS`).
