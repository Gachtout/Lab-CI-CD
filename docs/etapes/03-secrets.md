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

## Ce qu'on fait

- `.gitleaks.toml` : toutes les règles par défaut de Gitleaks, plus une règle maison `lab-fake-token` pour le format fictif `LABFAKE_` suivi de 24 caractères.
- `make secrets` : scanne **tout l'historique** git et produit un rapport SARIF.
- `make secrets-staged` : scanne seulement les fichiers indexés. C'est ce qu'appelle le hook pre-commit.
- Job `secrets` dans le workflow, avec `fetch-depth: 0` (sinon le runner ne récupère que le dernier commit) et publication du SARIF dans Code Scanning.

Pourquoi une règle maison ? Le secret de démonstration doit être manifestement faux et ne correspondre à aucun fournisseur. C'est aussi un cas réel : les jetons internes d'une entreprise ne sont connus d'aucun scanner tant qu'on n'a pas écrit la règle.

## Comment vérifier

```bash
make secrets
```

```text
INF 3 commits scanned.
INF no leaks found
```

## Casse-le volontairement

### 1. Le hook local bloque

```bash
pip install pre-commit && pre-commit install
printf 'API_TOKEN = "%s%s"\n' LABFAKE_ 7Q2M9X4K1Z8W3R6T5Y0B2N4C > app/config_local.py
git add app/config_local.py
git commit -m "ajoute la config"
```

Le jeton est assemblé par `printf` pour ne jamais figurer en clair dans cette documentation, que Gitleaks scanne aussi.

```text
secrets (gitleaks, fichiers indexés).....................................Failed
- hook id: gitleaks
- exit code: 2

WRN leaks found: 1
Finding:     API_TOKEN = "REDACTED
RuleID:      lab-fake-token
File:        app/config_local.py
Line:        1
```

Le commit n'existe pas : `git log` montre toujours le commit précédent.

### 2. Le hook local se contourne

```bash
git commit --no-verify -m "ajoute la config"
```

```text
 1 file changed, 1 insertion(+)
 create mode 100644 app/config_local.py
```

Le commit est créé. **Un hook local est une aide, pas une barrière** : il dépend de la bonne volonté de celui qui commite.

### 3. La CI rattrape, et supprimer ne suffit pas

```bash
make secrets                                   # échec : le secret est dans l'historique
git rm app/config_local.py && git commit -m "retire le secret"
make secrets                                   # échec, encore
```

```text
File:        app/config_local.py
Commit:      55ddc1260b7973a7ddd0411d065b4ac5a750467f
WRN leaks found: 1
make: *** [Makefile:90: secrets] Error 1
```

Le second scan échoue toujours : le secret est dans un commit passé. Pour nettoyer ton clone de test : `git reset --hard origin/main` (ou reviens au dernier commit sain).

### 4. Ce que l'outil ne voit pas

Indexe un fichier contenant `aws_access_key_id = AKIAIOSFODNN7EXAMPLE` et `password = "Password123!"` : `no leaks found`. La clé d'exemple d'AWS est volontairement ignorée par Gitleaks, et le mot de passe n'a ni format ni entropie reconnaissables.

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| `make secrets` (Gitleaks) | `wizcli dir scan` avec la détection de secrets activée, ou le scan des dépôts par le connecteur de gestion de code |
| Règle maison dans `.gitleaks.toml` | Règle de détection de secret personnalisée, définie dans la console |
| Code de sortie 1 | Politique de CI/CD Wiz en mode blocage : c'est elle qui décide du code de sortie de `wizcli` |

Différence de fond : Wiz peut relier un secret trouvé dans le code à la ressource cloud qu'il ouvre (et dire s'il est encore valide et ce qu'il expose). Gitleaks s'arrête à « cette chaîne ressemble à un secret ».
