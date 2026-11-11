# ADR 0003 : seuils de blocage et exceptions

- **Statut** : accepté
- **Date** : 2026-11-11

## Contexte

L'audit de l'existant a montré trois défauts : un job « secrets » vert sur une application censée en contenir, un seuil d'image limité à `CRITICAL`, et un Checkov qui bloquait sur tout, bruit compris.

## Décisions

1. **Secrets : toujours bloquant.** Aucun seuil, aucune sévérité.
2. **Vulnérabilités : `HIGH` et `CRITICAL` avec correctif disponible.** Bloquer sur une CVE sans correctif n'apporte rien à celui qui ne peut pas la corriger.
3. **Checkov : tout échec bloque, sauf exception explicite.** En version libre, Checkov n'expose pas de sévérité : on ne peut pas filtrer par gravité. Le bruit est traité par deux mécanismes : règles écartées pour tout le dépôt (`.checkov.yaml`), exceptions datées par ressource (commentaires).
4. **Exceptions : justification et date d'expiration obligatoires.** Trivy applique l'expiration ; `scripts/check-exceptions.sh` la vérifie pour Checkov.
5. **SARIF filtré comme le gate.** Sans filtre, l'image saine produisait 201 entrées dans le rapport, presque toutes sans correctif. Code Scanning affiche donc ce qui bloque.
6. **Un seul statut requis côté sécurité, `security-gate`**, plus `plan`. Tout résultat autre que `success` bloque, y compris `skipped`.
7. **Un auto-test des contrôles.** `make demo-bad` échoue si une faille de référence n'est plus détectée. Le job `gates-selftest` le rejoue ; il est informatif et non requis, pour ne pas bloquer une fusion sur une panne de registre.

## Conséquence connue

Les seuils vivent dans le dépôt : une PR peut les abaisser. C'est assumé et documenté à l'[étape 9](../etapes/09-branch-protection.md), avec les parades (`CODEOWNERS`, politique centralisée).
