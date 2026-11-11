# Étape 9 : la protection de branche, la vraie barrière

!!! warning "Non exécuté par l'auteur du lab"
    Cette étape configure GitHub. Elle n'a pas pu être testée avant la création du dépôt : le JSON et le script sont valides syntaxiquement, pas encore éprouvés. Les sorties attendues ci-dessous sont à confirmer et à capturer au [point de contrôle 2](../reference/checkpoints.md).

## Objectif

Faire en sorte que **personne**, administrateur compris, ne puisse amener du code sur `main` sans passer par les contrôles.

## Le concept, depuis zéro

Jusqu'ici, tout repose sur une hypothèse : le développeur ouvre une PR et attend le résultat. Rien ne l'y oblige. Qui décide vraiment de ce qui entre dans `main` ? **Le serveur git**, et lui seul : c'est lui qui accepte ou refuse un `git push`.

| Couche | Où | Qui peut la contourner | Rôle réel |
|---|---|---|---|
| 1. Hook pre-commit | Poste du développeur | Le développeur (`--no-verify`, ou ne jamais l'installer) | Retour rapide, confort |
| 2. Pipeline CI | Runner GitHub | Quiconque peut pousser sur `main` sans PR, ou fusionner une PR rouge | Analyse complète, produit un verdict |
| 3. Ruleset de branche | Serveur GitHub | Personne, si la liste de contournement est vide | **Applique** le verdict |

La couche 2 sans la couche 3 est un voyant sur un tableau de bord : il s'allume, et on peut continuer à rouler. La couche 3 relie le voyant au frein.

**Ce que fait un ruleset.** C'est une liste de conditions que le serveur vérifie avant de modifier une référence. Celui du lab en pose quatre sur `main` :

1. interdiction de supprimer la branche ;
2. interdiction de réécrire l'historique (`push --force`) ;
3. toute modification passe par une pull request ;
4. la PR ne peut être fusionnée que si les statuts `security-gate` et `plan` sont verts, sur une branche à jour.

**La push protection** agit encore plus tôt : GitHub analyse le contenu d'un `git push` et le refuse s'il contient un secret d'un format connu (jeton GitHub, clé AWS…). Elle s'applique à toutes les branches.

## Ce qu'on fait

- `.github/rulesets/main.json` : le ruleset, versionné dans le dépôt.
- `scripts/setup-github.sh` : active le secret scanning et la push protection, crée ou met à jour le ruleset, crée l'environnement `dev` avec approbation manuelle (utilisé à l'étape 10).

```json title=".github/rulesets/main.json (extrait)"
"bypass_actors": [],
"rules": [
  { "type": "deletion" },
  { "type": "non_fast_forward" },
  { "type": "pull_request", "parameters": { "required_approving_review_count": 0, … } },
  { "type": "required_status_checks", "parameters": {
      "strict_required_status_checks_policy": true,
      "required_status_checks": [ { "context": "security-gate" }, { "context": "plan" } ] } }
]
```

Deux réglages à savoir défendre :

- **`bypass_actors` vide** : aucun rôle n'est exempté. Si l'administrateur peut contourner, la règle protège contre les erreurs, pas contre un compte compromis.
- **`required_approving_review_count: 0`** : sur un dépôt personnel, on ne peut pas approuver sa propre PR ; exiger une revue bloquerait tout. En équipe, cette valeur passe à 1 ou 2.

## Comment vérifier

```bash
scripts/setup-github.sh
gh api repos/:owner/:repo/rulesets --jq '.[] | {name, enforcement}'
```

Puis trois essais, à faire dans l'ordre.

### 1. Push direct sur `main`

```bash
git switch main
git commit --allow-empty -m "test: push direct"
git push origin main
```

Attendu : refus par le serveur, avec un message de violation de règle du dépôt. Annule le commit local : `git reset --hard origin/main`.

### 2. La PR « bad »

```bash
scripts/demo.sh branch
git push -u origin demo/bad
gh pr create --base main --head demo/bad --title "demo: PR vulnérable" --body "Doit être bloquée."
```

Attendu : jobs `secrets`, `sast`, `sca`, `image`, `iac`, `build-test` rouges, `security-gate` rouge, `plan` rouge (policies), bouton de fusion désactivé, commentaire de synthèse sur la PR. Ferme la PR sans la fusionner et supprime la branche.

### 3. La PR « fix »

Une PR avec un changement sain (par exemple une ligne de documentation) : tout est vert, la fusion est possible.

## Casse-le volontairement

### Contourner en tant qu'administrateur

Essaie de fusionner la PR « bad » : `gh pr merge --admin --squash`. Avec `bypass_actors` vide, le refus est attendu. Ajoute ensuite ton rôle dans la liste de contournement depuis l'interface, réessaie, constate que ça passe, puis **retire-le** en relançant `scripts/setup-github.sh`. Tu viens de mesurer ce que vaut une règle avec exemption.

### Pousser un vrai format de secret

Sur une branche de test, commite un fichier contenant une chaîne au format d'un jeton personnel GitHub (préfixe `ghp_` suivi de 36 caractères alphanumériques), puis pousse. Deux issues possibles, toutes deux instructives : la push protection refuse le push, ou elle laisse passer parce que la chaîne ne satisfait pas la validation propre à ce format. Dans le second cas, c'est le job `secrets` qui rattrape. Note ce que tu observes.

### Affaiblir le contrôle depuis une PR

Ouvre une PR qui change `TRIVY_SEVERITY ?= HIGH,CRITICAL` en `CRITICAL` dans le `Makefile`. Elle sera verte. **C'est la limite de ce lab** : les seuils vivent dans le dépôt, donc une PR peut les modifier. Les parades :

- un fichier `CODEOWNERS` qui attribue `Makefile`, `.github/`, `policies/` et les fichiers d'exceptions à l'équipe sécurité, avec `require_code_owner_review` à `true` (demande au moins deux personnes) ;
- sortir les seuils du dépôt : workflow requis au niveau de l'organisation, ou politique centralisée comme le fait Wiz.

## Côté Wiz, en entreprise

Wiz ne remplace pas cette étape. **Wiz produit un verdict ; c'est la plateforme git qui l'applique.** Sans statut requis, un `wizcli` en échec n'empêche aucune fusion.

| Ici | En entreprise |
|---|---|
| Statut requis `security-gate` | Statut requis sur le job qui exécute `wizcli` |
| Ruleset dans un fichier JSON | Rulesets au niveau de l'**organisation**, hérités par tous les dépôts, hors de portée des équipes |
| Push protection GitHub | Inchangé, complété par le scan de secrets de Wiz |
| Seuils modifiables par PR | Politiques Wiz dans la console : une PR ne peut pas les baisser |

C'est souvent le point faible d'un déploiement : l'outil est branché partout, mais en mode rapport, sans statut requis. La question à poser en arrivant est « quel statut est exigé, et qui peut le contourner ? ».
