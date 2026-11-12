# Étape 9 : la protection de branche, la vraie barrière

!!! warning "Vérification statique uniquement"
    `make check-etape-09` lit ton fichier JSON et ton script. Il ne contacte jamais GitHub et **n'exécute pas** ton script.

    | Vérifié par le check | À tester toi-même sur GitHub |
    |---|---|
    | Structure du ruleset (cible, contournement, règles, statuts requis) | Le ruleset est accepté par l'API et apparaît dans *Settings → Rules* |
    | Syntaxe du script, fichier qu'il applique, option de push protection | Le script s'exécute sans erreur, et une seconde exécution ne crée pas de doublon |
    | — | Un push direct sur `main` est refusé |
    | — | Une PR aux contrôles rouges ne peut pas être fusionnée, même par un administrateur |
    | — | La push protection refuse (ou non) un secret d'un format connu |

    Appliquer un ruleset modifie le dépôt : fais-le quand tu es prêt, pas avant d'avoir un pipeline vert sur `main`.

## Objectif

Faire en sorte que **personne**, administrateur compris, ne puisse amener du code sur `main` sans passer par les contrôles.

## Le concept, depuis zéro

Jusqu'ici, tout repose sur une hypothèse : le développeur ouvre une PR et attend le résultat. Rien ne l'y oblige. Qui décide vraiment de ce qui entre dans `main` ? **Le serveur git**, et lui seul : c'est lui qui accepte ou refuse un `git push`.

| Couche | Où | Qui peut la contourner | Rôle réel |
|---|---|---|---|
| 1. Hook pre-commit | Poste du développeur | Le développeur (une option de git saute les hooks, ou il suffit de ne jamais l'installer) | Retour rapide, confort |
| 2. Pipeline CI | Runner GitHub | Quiconque peut pousser sur `main` sans PR, ou fusionner une PR rouge | Analyse complète, produit un verdict |
| 3. Ruleset de branche | Serveur GitHub | Personne, si la liste de contournement est vide | **Applique** le verdict |

La couche 2 sans la couche 3 est un voyant sur un tableau de bord : il s'allume, et on peut continuer à rouler. La couche 3 relie le voyant au frein.

**Ce que fait un ruleset.** C'est une liste de conditions que le serveur vérifie avant de modifier une référence. Celui du lab en pose quatre sur `main` :

1. interdiction de supprimer la branche ;
2. interdiction de réécrire l'historique (`push --force`) ;
3. toute modification passe par une pull request ;
4. la PR ne peut être fusionnée que si les statuts `security-gate` et `plan` sont verts, sur une branche à jour.

**La push protection** agit encore plus tôt : GitHub analyse le contenu d'un `git push` et le refuse s'il contient un secret d'un format connu (jeton GitHub, clé AWS…). Elle s'applique à toutes les branches.

## Ce qui t'est fourni

- Rien : tu écris le ruleset et le script de zéro.

## Énoncé

Livrables :

- `.github/rulesets/main.json`.
- `scripts/setup-github.sh`, exécutable, qui applique la configuration avec `gh`.

Contraintes :

1. Le ruleset est actif et vise la branche par défaut.
2. Personne ne peut le contourner : la liste des acteurs exemptés est vide.
3. La branche ne peut être ni supprimée, ni réécrite par un push forcé.
4. Toute modification passe par une pull request.
5. La fusion exige les statuts `security-gate` et `plan`, sur une branche à jour.
6. Le script applique le fichier de ruleset versionné et active la protection contre le push de secrets.
7. Le script est rejouable : relancé, il met à jour le ruleset existant au lieu d'en créer un second.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Ruleset | `.github/rulesets/main.json`, au format de l'API REST des rulesets de dépôt |
| Script | `scripts/setup-github.sh` |
| Statuts requis | `security-gate`, `plan` (les noms de tes jobs) |

## Critère de réussite

```bash
make check-etape-09
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Un ruleset est un objet JSON que l'API REST de GitHub sait créer et mettre à jour. Cherche « repository rulesets » dans la référence de l'API.
    - `gh api` envoie un fichier comme corps de requête.

??? tip "Indice 2 : les points qui coincent"
    - Les règles sont une liste d'objets typés ; certaines ont des paramètres.
    - La branche par défaut se désigne par un mot-clé spécial plutôt que par son nom.
    - Pour être rejouable, le script doit d'abord chercher un ruleset du même nom.
    - Le secret scanning et la push protection se règlent sur le dépôt lui-même, pas dans le ruleset.

??? tip "Indice 3 : presque la réponse"
    - Quatre types de règles suffisent : suppression, avance non rapide, pull request, statuts requis.
    - Les statuts requis sont une liste de contextes, avec un booléen qui impose une branche à jour.
    - Sur un dépôt personnel, le nombre d'approbations requises vaut zéro : on ne peut pas approuver sa propre PR.
    - Création par la méthode POST sur la collection, mise à jour par PUT sur l'identifiant trouvé.
    - Les réglages de sécurité du dépôt passent par une requête de modification partielle du dépôt, avec des champs imbriqués.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Pousse directement sur `main`. Note le message exact du refus.
2. Ouvre une PR aux contrôles rouges et tente de la fusionner en administrateur.
3. Ajoute ton rôle à la liste de contournement, réessaie, puis retire-le en relançant ton script. Qu'as-tu mesuré ?
4. Ouvre une PR qui baisse un seuil dans le `Makefile`. Elle est verte. Qu'est-ce que cela dit de ce lab ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Pourquoi le pipeline seul ne bloque-t-il rien ?
2. Qui peut contourner chacune des trois couches (hook, CI, ruleset) ?
3. Pourquoi vider la liste de contournement, y compris pour les administrateurs ?
4. Pourquoi exiger une branche à jour avant la fusion ?
5. Que protège la push protection que le pipeline ne protège pas ?
6. Les seuils vivent dans le dépôt. Cite deux façons de les mettre hors de portée d'une PR.
7. En arrivant dans une équipe, quelle question poses-tu pour savoir si leur outil de scan bloque réellement quelque chose ?

## Côté Wiz, en entreprise

Wiz ne remplace pas cette étape. **Wiz produit un verdict ; c'est la plateforme git qui l'applique.** Sans statut requis, un `wizcli` en échec n'empêche aucune fusion.

| Ici | En entreprise |
|---|---|
| Statut requis `security-gate` | Statut requis sur le job qui exécute `wizcli` |
| Ruleset dans un fichier JSON | Rulesets au niveau de l'**organisation**, hérités par tous les dépôts, hors de portée des équipes |
| Push protection GitHub | Inchangé, complété par le scan de secrets de Wiz |
| Seuils modifiables par PR | Politiques Wiz dans la console : une PR ne peut pas les baisser |

C'est souvent le point faible d'un déploiement : l'outil est branché partout, mais en mode rapport, sans statut requis. La question à poser en arrivant est « quel statut est exigé, et qui peut le contourner ? ».

## Corrigé

À ouvrir seulement une fois `make check-etape-09` vert et les questions travaillées : [`etape-09-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-09-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le script du corrigé de cette étape ne crée qu'un environnement `dev` ; l'étape 10 ajoute `dev-plan` et limite les deux à la branche `main`.
