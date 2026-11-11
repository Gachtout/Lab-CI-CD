# Étape 7 : scan IaC et policies maison

## Objectif

Refuser une infrastructure dangereuse **avant** qu'elle n'existe, avec deux scanners du marché et des règles écrites par toi.

## Le concept, depuis zéro

À l'étape 6, Terraform a accepté un security group ouvert au monde entier : la demande était cohérente. Il manque quelqu'un pour dire qu'elle est mauvaise. Deux façons de le faire, qui ne voient pas la même chose.

| | Analyse **statique** du code | Analyse du **plan** |
|---|---|---|
| Entrée | Les fichiers `*.tf` | `tfplan.json`, produit par `terraform plan` |
| Outils ici | Trivy config, Checkov | Conftest (moteur OPA, langage Rego) |
| Avantage | Immédiate, aucun `init`, pointe la ligne fautive | Voit les **valeurs finales**, après variables, boucles et modules |
| Limite | Doit deviner la valeur des variables et des `for_each` | Demande un plan, donc un `init` et des providers |

**Pourquoi des règles maison ?** Les scanners embarquent des centaines de règles génériques (« un bucket ne doit pas être public »). Ils ne connaissent pas *tes* règles : tags obligatoires, types de ressources interdits, régions autorisées. Une policy-as-code est une règle interne écrite dans un langage exécutable, versionnée et testée comme du code.

**Rego en trois idées :**

- Une règle `deny contains msg if { … }` ajoute un message à l'ensemble `deny` quand **toutes** les lignes du bloc sont vraies.
- `some rc in input.resource_changes` parcourt le plan.
- Piège classique : un attribut absent vaut `null` dans le plan, et `not x` est faux quand `x` vaut `null`. On compare donc explicitement : `x != true`.

## Ce qui t'est fourni

- Les images `CHECKOV_IMAGE` et `CONFTEST_IMAGE`.
- Les cibles `iac-trivy`, `iac-checkov`, `iac`, `policy-test`, `policy`, vides.
- Des plans de référence dans `checks/fixtures/` : un plan conforme et quatre plans fautifs. Lis-les, ils montrent la structure d'un plan.

## Énoncé

Livrables :

- Les cibles `make iac-trivy`, `make iac-checkov`, `make iac`, `make policy-test`, `make policy`.
- Des policies Rego dans `policies/`, avec leurs tests unitaires.
- Un job `iac` dans `pr-security.yml`, et l'appel des policies dans `terraform-plan.yml`.
- Si nécessaire, des exceptions justifiées (voir l'étape 8 pour leur format).

Contraintes :

1. `make iac-trivy` réussit sur ton code et échoue sur un bucket exposable publiquement (constats `HIGH` et `CRITICAL`).
2. `make iac-checkov` réussit sur ton code et échoue sur le même bucket.
3. Tes policies acceptent un plan conforme : celui de `checks/fixtures/plan-sain.json`, et le tien.
4. Tes policies refusent un bucket dont l'un des quatre blocages d'accès public n'est pas actif.
5. Tes policies refusent une règle d'entrée ouverte à tout Internet, en IPv4 comme en IPv6.
6. Tes policies refusent une ressource taggable à laquelle il manque l'un des tags `Project`, `Environment`, `Owner`, `ManagedBy`.
7. Tes policies refusent la création d'une ressource payante (au minimum une NAT Gateway).
8. `make policy-test` exécute au moins quatre tests unitaires de policies, tous réussis.
9. `make policy` calcule le plan, applique les policies à ce plan, et échoue si l'une d'elles le refuse.
10. Le job `iac` lance les deux scanners ; le workflow `terraform-plan` appelle `make policy`.

## Contrat d'interface

Ces noms sont imposés : la vérification en dépend.

| Élément | Valeur imposée |
|---|---|
| Policies | dossier `policies/`, règles `deny`, évaluées avec tous les espaces de noms |
| Cibles `make` | `iac-trivy`, `iac-checkov`, `iac`, `policy-test`, `policy` |
| Entrée des policies | `reports/tfplan.json` |
| Nom du job | `iac` |

## Critère de réussite

```bash
make check-etape-07
```

Chaque ligne `ECHEC [Cn]` renvoie à la contrainte `n` ci-dessus et donne l'emplacement en cause, jamais la correction. Les journaux détaillés sont dans `reports/checks/`. Teste toujours en local avant de pousser.

## Indices

Ouvre-les dans l'ordre, et seulement après avoir cherché.

??? tip "Indice 1 : par où commencer"
    - Deux familles d'outils : ceux qui lisent le code, ceux qui lisent le plan. Demande-toi ce que chacun peut voir.
    - Ouvre `checks/fixtures/plan-sain.json` : une policy sur le plan parcourt la liste `resource_changes`.

??? tip "Indice 2 : les points qui coincent"
    - En Rego, une règle `deny` ajoute un message quand toutes ses lignes sont vraies.
    - Un attribut absent vaut `null` dans le plan, et la négation d'une valeur `null` ne se comporte pas comme tu l'attends : compare explicitement.
    - Ignore les ressources que le plan supprime ou se contente de lire.
    - Conftest a une sous-commande pour les tests unitaires : une règle de test fournit une entrée fictive avec le mot-clé `with`.
    - Si un scanner signale un point que tu assumes (une clé KMS payante, par exemple), ne baisse pas le seuil : trace une exception.

??? tip "Indice 3 : presque la réponse"
    - Factorise dans un paquet commun l'ensemble des ressources créées ou modifiées, puis écris une policy par sujet.
    - Tags : la différence entre l'ensemble des tags obligatoires et l'ensemble des clés de `tags_all`.
    - Réseau : il existe trois façons de déclarer une règle d'entrée dans le provider AWS ; les plans de référence utilisent la plus récente.
    - Coût : une table associant un type de ressource à la raison de son interdiction.
    - Checkov se configure par un fichier à la racine ; Trivy accepte un fichier d'exceptions avec une date d'expiration par entrée.

## Casse-le volontairement

Note ce que tu observes dans `docs/journal.md` : ce sont tes sorties, pas celles d'un corrigé.

1. Ouvre le security group à tout Internet via la variable de ton environnement, puis lance les deux scanners et les policies. Qui le voit, qui ne le voit pas, et pourquoi ?
2. Ajoute une NAT Gateway à l'environnement et lance `make policy`.
3. Supprime un cas `null` de tes policies et regarde quel test unitaire échoue.

## Défends ton choix

À savoir expliquer à l'oral, sans notes.

1. Quelle différence entre analyser le code Terraform et analyser le plan ? Donne un défaut que seule la seconde voit.
2. Pourquoi écrire des policies maison alors que les scanners ont des centaines de règles ?
3. Pourquoi tester unitairement une policy ?
4. Explique le piège de la valeur `null` en Rego.
5. Un scanner est vert. Qu'est-ce que cela prouve, et qu'est-ce que cela ne prouve pas ?
6. Deux scanners IaC : redondance utile ou bruit ? Comment décides-tu ?
7. Comment transposerais-tu ces policies dans un outil commercial comme Wiz ?

## Côté Wiz, en entreprise

| Ici | Avec Wiz |
|---|---|
| Trivy config, Checkov | `wizcli iac scan` sur le répertoire, avec les règles de configuration cloud de Wiz |
| Conftest sur `tfplan.json` | `wizcli iac scan` accepte aussi un plan Terraform JSON : même bénéfice des valeurs résolues |
| Policies Rego dans `policies/` | Règles de configuration cloud personnalisées, écrites **en Rego** dans la console |
| Tests `conftest verify` | Pas d'équivalent intégré : garder des tests unitaires de ses règles reste une bonne pratique |

Le Rego appris ici est donc directement réutilisable. La structure d'entrée diffère (Wiz expose sa propre représentation de la ressource), la logique `deny si…` est la même.

## Corrigé

À ouvrir seulement une fois `make check-etape-07` vert et les questions travaillées : [`etape-07-solution`](https://github.com/Gachtout/Lab-CI-CD/tree/etape-07-solution). La version finale de tout le parcours est sur la branche [`solution`](https://github.com/Gachtout/Lab-CI-CD/tree/solution).

Corrections apportées plus tard à ce corrigé :

- Aucune correction ultérieure sur les policies. Les exceptions du bootstrap sont ajoutées à l'étape 10.
