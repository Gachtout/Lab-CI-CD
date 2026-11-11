# Ce que je ferais en production

Le lab fait des choix adaptés à un dépôt personnel et gratuit. Voici ce qui changerait dans une organisation, par ordre de priorité.

## Gouvernance

| Dans le lab | En production |
|---|---|
| Seuils dans le `Makefile`, modifiables par PR | Workflow requis au niveau de l'organisation, ou politique centralisée de l'outil de scan |
| Aucune revue exigée | Au moins une approbation, `CODEOWNERS` sur `.github/`, `policies/`, les fichiers d'exceptions et le `Makefile` |
| Ruleset par dépôt | Rulesets d'organisation, hérités, hors de portée des équipes |
| Exceptions dans des fichiers | Registre d'exceptions avec demandeur, approbateur, échéance et revue périodique |

## Chaîne d'approvisionnement

- **Renovate** pour monter les digests d'images, les SHA d'actions et les versions de providers, par PR, avec le pipeline comme filet.
- **Signature et provenance** de l'image (cosign, attestations de build) et vérification à l'admission.
- **Liste blanche d'actions** au niveau de l'organisation.
- **zizmor** en complément d'actionlint pour l'audit de sécurité des workflows.
- **Registre interne** ou cache de registre, pour ne dépendre ni des limites de débit ni de la disponibilité d'un registre public.

## Terraform

- **Appliquer le plan relu** : stocker le fichier de plan chiffré dans un emplacement privé et l'appliquer tel quel, au lieu de le recalculer.
- **Détection de dérive** planifiée (plan nocturne, alerte si différence).
- **Un compte AWS par environnement**, un état par composant, des rôles distincts par compte.
- **Limites de permissions et politiques de contrôle de service** au niveau de l'organisation AWS : interdire à la racine ce que le lab n'interdit que par policy (régions, types de ressources).
- **Chiffrement par clé gérée** (KMS) du bucket d'état et des données, journaux d'accès S3, flow logs du VPC : les quatre exceptions du lab disparaissent.
- **Modules versionnés** dans un registre, plutôt que des chemins relatifs.

## Détection et réponse

- **Journaliser** : CloudTrail sur toute l'organisation, et alerte sur `AssumeRoleWithWebIdentity` depuis un `sub` inattendu.
- **Centraliser les constats** (DefectDojo, ou la console de l'outil commercial) pour dédoublonner et suivre les délais de correction.
- **Re-scanner en continu** les images déployées à partir des SBOM (Dependency-Track).
- **Révoquer automatiquement** un secret détecté quand le fournisseur le permet.

## Pipeline

- Runners éphémères auto-hébergés si le code ou les cibles sont privés, avec sortie réseau filtrée.
- Cache de la base de vulnérabilités et des providers, pour la vitesse et la résilience.
- Mode audit avant mode blocage lors de l'introduction d'un nouveau contrôle : mesurer le bruit, puis bloquer.
- Délai de grâce sur les nouvelles CVE (par exemple sept jours pour une `HIGH`), pour ne pas casser toutes les PR le jour d'une publication.

## Ce que je garderais tel quel

- Le `Makefile` comme interface unique entre le poste et la CI.
- `permissions: {}` par défaut et les droits déclarés par job.
- OIDC avec comparaison stricte du `sub`.
- L'auto-test des contrôles (`make demo-bad`).
- Les policies appliquées au plan, pas seulement au code.
