# Étape 3 : détection de secrets

## Objectif

Empêcher qu'un secret (jeton, clé, mot de passe) atteigne le dépôt, et savoir quoi faire quand c'est déjà arrivé.

## Le concept, depuis zéro

**Pourquoi un secret dans git est-il plus grave qu'un bug ?** Git ne modifie jamais le passé : chaque commit est conservé. Supprimer le secret dans un commit suivant ne l'efface pas, il reste lisible dans l'historique par quiconque clone le dépôt. Un secret poussé doit donc être considéré comme **compromis** : la seule vraie correction est de le **révoquer**, pas de le supprimer.

**Comment un outil reconnaît-il un secret ?** Il ne comprend pas le code. Il applique deux techniques :

- des **expressions régulières** propres à chaque fournisseur (un jeton GitHub commence par `ghp_`, une clé AWS par `AKIA`) ;
- une mesure d'**entropie** : une chaîne très aléatoire a plus de chances d'être une clé qu'un mot.

Conséquence directe : un mot de passe faible et lisible (`Password123!`) n'est **pas** détecté. Un scanner de secrets trouve les secrets bien formés, pas les mauvaises pratiques.

**Où placer le contrôle ?** À trois endroits, du plus rapide au plus sûr : sur le poste (hook pre-commit), dans la CI (cette étape), sur le serveur (étape 9). Chacun compense la faiblesse du précédent.

## Ce qui t'est fourni

- L'image `GITLEAKS_IMAGE` dans la plomberie.
- Les cibles `secrets` et `secrets-staged`, vides.

## Énoncé

Livrables :

- `.gitleaks.toml`.
- Les cibles `make secrets` et `make secrets-staged`.
- `.pre-commit-config.yaml` avec un hook de détection de secrets.
- Un job `secrets` dans `pr-security.yml`.

Contraintes :

1. `make secrets` réussit sur un historique sain et échoue dès qu'un secret d'un format connu d'un fournisseur est commité : les règles par défaut de l'outil restent actives.
2. Une règle maison, d'identifiant `lab-fake-token`, détecte le format interne fictif du lab : `LABFAKE_` suivi de 24 caractères parmi `A-Z` et `0-9`.
3. `make secrets` analyse tout l'historique git : un secret commité puis supprimé dans un commit suivant est encore détecté.
4. `make secrets` produit un rapport SARIF dans `reports/gitleaks.sarif`.
5. `make secrets-staged` n'analyse que les fichiers indexés, pas encore commités.
6. Un hook pre-commit appelle `make secrets-staged`.
7. Le job `secrets` récupère tout l'historique avant d'appeler `make secrets`.
8. La valeur d'un secret détecté n'apparaît jamais en clair dans la sortie.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Configuration | `.gitleaks.toml` |
| Cibles `make` | `secrets`, `secrets-staged` |
| Identifiant de la règle maison | `lab-fake-token` |
| Rapport | `reports/gitleaks.sarif` |
| Nom du job | `secrets` |

## Critère de réussite

```bash
make check-etape-03
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Gitleaks a plusieurs modes d'analyse : l'historique git, un répertoire, ou les seuls changements en attente. Lis `gitleaks --help`.
    - Une configuration personnalisée remplace les règles par défaut, sauf si on demande explicitement de les étendre.

??? tip "Indice 2 : les points qui coincent"
    - Le dépôt monté dans le conteneur n'appartient pas forcément à l'utilisateur du conteneur : git refuse alors de le lire. Cherche `safe.directory`.
    - Par défaut, l'action de récupération du code ne ramène que le dernier commit.
    - Un hook `pre-commit` de type local peut lancer n'importe quelle commande du système.
    - Une option de Gitleaks masque la valeur des secrets dans sa sortie.

??? tip "Indice 3 : presque la réponse"
    - La configuration a une section d'extension avec un booléen, puis un tableau de règles : identifiant, description, expression régulière, mots-clés.
    - La configuration git peut se passer au conteneur par trois variables d'environnement `GIT_CONFIG_*`.
    - Le mode d'analyse de l'historique accepte deux options pour ne regarder que ce qui est indexé avant un commit.
    - Le format et le chemin du rapport sont deux options distinctes de Gitleaks.
    - Dans le job, la profondeur de récupération vaut zéro pour tout l'historique.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Installe le hook, crée un fichier contenant un jeton au format du lab (assemble-le avec `printf` pour ne pas l'écrire en clair), puis tente un commit. Refais-le avec `--no-verify`.
2. Commite le jeton, supprime le fichier dans un second commit, puis relance `make secrets`.
3. Indexe un fichier contenant la clé d'exemple de la documentation AWS et un mot de passe faible et lisible. Que dit l'outil, et pourquoi ?

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Pourquoi supprimer un secret d'un dépôt ne suffit-il pas ? Quelle est la seule vraie correction ?
2. Comment un scanner reconnaît-il un secret ? Que ne peut-il pas voir ?
3. Le hook local se contourne en une option. À quoi sert-il alors ?
4. Pourquoi scanner tout l'historique et pas seulement le dernier commit ?
5. Pourquoi écrire une règle maison ? Donne un cas réel en entreprise.
6. Un faux positif bloque l'équipe. Quelles sont tes options, de la meilleure à la pire ?
7. Pourquoi masquer la valeur du secret dans les journaux de CI ?

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make secrets` (Gitleaks) | `wizcli dir scan` avec la détection de secrets activée, ou le scan des dépôts par le connecteur de gestion de code |
| Règle maison dans `.gitleaks.toml` | Règle de détection de secret personnalisée, définie dans la console |
| Code de sortie 1 | Politique de CI/CD Wiz en mode blocage : c'est elle qui décide du code de sortie de `wizcli` |

Différence de fond : Wiz peut relier un secret trouvé dans le code à la ressource cloud qu'il ouvre (et dire s'il est encore valide et ce qu'il expose). Gitleaks s'arrête à « cette chaîne ressemble à un secret ».

## Corrigé

À ouvrir seulement une fois `make check-etape-03` vert et les questions travaillées : [`etape-03-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-03-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Le corrigé de cette étape publie le rapport dans Code Scanning sans `continue-on-error` : sur un dépôt privé, le job échoue. Corrigé après la première exécution réelle (voir l'étape 4, contrainte 8).
