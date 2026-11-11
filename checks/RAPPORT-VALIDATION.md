# Rapport de validation des vérifications

Produit par `make test-checks` le 2026-11-11, corrigé lu depuis la branche `solution` (`c9fa885`).
Ce fichier est un instantané : relance `make test-checks` après toute modification de `checks/` ou des pages.

## Résultat

- 11 étapes : chaque vérification passe sur le corrigé et échoue sur le squelette.
- 87 mutants, un ou plusieurs par contrainte : tous détectés, et par la contrainte attendue.
- Progression, N = 1 à 10 : la vérification N passe, la vérification N+1 échoue.
- Cohérence : 86 contraintes numérotées, chacune avec au moins un contrôle et un mutant.
- Fuite : 564 lignes des livrables du corrigé cherchées à l'identique sur cette branche, 0 trouvée.

## Limites connues

1. **Étapes 9 et 10 : statique uniquement.** Rien n'est exécuté sur GitHub ni sur AWS. Le ruleset n'a jamais été soumis à l'API, le bootstrap jamais appliqué, les politiques IAM jamais éprouvées.
2. **Étape 10, politique de confiance : lecture du code, pas du plan.** Les conditions sur le sujet et l'audience sont cherchées par motif dans les fichiers `.tf`. Une politique écrite autrement (construite dynamiquement, par exemple) peut être refusée à tort ou acceptée à tort.
3. **Étape 10, cibles `aws-*` et étape 11, cible `prowler` : jamais exécutées.** Seule la commande que `make` lancerait est lue (`make -n`). La confirmation `AWS_CONFIRM` est vérifiée par sa présence dans cette commande, pas par un refus réel.
4. **Étape 8, commentaire de PR : structure seulement.** Droits, condition « PR interne » et absence d'interpolation de données non fiables sont vérifiés dans le YAML ; la publication réelle du commentaire ne l'est pas.
5. **Étape 5, contrainte 1 : dépend de la date.** Le mutant « outil d'installation laissé dans l'image » n'est détecté que tant que les bibliothèques embarquées par `pip` ont une vulnérabilité `HIGH` corrigeable. Plus généralement, le corrigé peut devenir rouge quand de nouvelles CVE sortent : c'est le comportement voulu d'un scanner, mais `make test-checks` peut alors échouer sans que les vérifications soient en cause.
6. **Contrôles par motif.** Les seuils par défaut (étape 8), le socket Docker (étape 5) et le backend S3 (étape 6) sont vérifiés par recherche de texte. Une écriture inhabituelle mais correcte peut être refusée.
7. **Un contrôle « doit échouer » est satisfait par tout échec.** Il est toujours couplé à un contrôle « doit réussir » sur le dépôt sain, ce qui écarte une cible qui échouerait systématiquement, mais pas une cible qui échouerait pour une autre raison que la faute injectée.
8. **Progression : un accommodement.** Le corrigé final valide aussi `terraform/bootstrap`, qui n'existe qu'à l'étape 10 ; pour N = 6 à 9, le banc crée ce dossier vide. Les corrigés partiels sont reconstitués à partir de la branche `solution` finale, pas à partir des branches `etape-NN-solution`, qui sont des instantanés historiques.
9. **Fuite : comparaison ligne à ligne.** Seules les lignes d'au moins 30 caractères, hors commentaires, sont cherchées à l'identique. Une reformulation ou un fragment plus court passerait. Les pages gardent les sections « concept » d'origine, qui décrivent en prose certains choix du corrigé, et `docs/adr/` dévoile sa conception.
10. **Les vérifications s'exécutent par étape**, sans relancer les précédentes. `make check-tout` les enchaîne.
11. **Environnement de validation.** Le banc a tourné sous Linux, en root, derrière un proxy, avec un miroir de Docker Hub. Il n'a pas été rejoué sous WSL2 ni en utilisateur non privilégié.

12. **Emplacement dans les messages d'échec.** Les contrôles de structure citent le fichier et la ligne. Les contrôles de comportement citent la cible `make` et le journal (`reports/checks/`), pas une ligne : un comportement n'a pas de ligne fautive unique.

## Sortie complète de `make test-checks`

```text
== Étape 01
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   déclenchement manuel retiré
  PASS  mutant c2   détecté par C2   droits par défaut rendus au jeton
  PASS  mutant c3   détecté par C3   une action épinglée par tag
  PASS  mutant c4   détecté par C4   persistance du jeton réactivée
  PASS  mutant c5   détecté par C5   le job n'appelle plus make
  PASS  mutant c6   détecté par C6   artifact non publié en cas d'échec
  PASS  mutant c7   détecté par C7   durée maximale retirée
  PASS  mutant c8   détecté par C8   annulation de l'exécution précédente retirée
  PASS  mutant c9   détecté par C9   pipefail retiré : le tube masque l'échec
== Étape 02
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   image de base sans digest
  PASS  mutant c2   détecté par C2   exécution en root
  PASS  mutant c3   détecté par C3   contrôle de santé retiré
  PASS  mutant c4   détecté par C4   cache pip conservé dans l'image
  PASS  mutant c5   détecté par C5   la cible test ne lance plus les tests
  PASS  mutant c6   détecté par C6   la cible build ignore la variable IMAGE
  PASS  mutant c7   détecté par C7   le job build-test ne lance plus les tests
== Étape 03
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   règles par défaut désactivées
  PASS  mutant c2   détecté par C2   règle maison qui ne reconnaît plus le format du lab
  PASS  mutant c3   détecté par C3   scan du répertoire courant au lieu de l'historique
  PASS  mutant c4   détecté par C4   rapport écrit ailleurs qu'à l'emplacement imposé
  PASS  mutant c5   détecté par C5   la cible du hook ne regarde plus les fichiers indexés
  PASS  mutant c6   détecté par C6   le hook appelle le scan d'historique
  PASS  mutant c7   détecté par C7   historique tronqué dans le job
  PASS  mutant c8   détecté par C8   secrets affichés en clair
== Étape 04
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   jeux de règles communautaires retirés
  PASS  mutant c2   détecté par C2   règle maison sur les secrets de configuration retirée
  PASS  mutant c3   détecté par C3   règle maison sur le mode debug retirée
  PASS  mutant c4   détecté par C4   le SAST bloque sur toutes les sévérités
  PASS  mutant c5   détecté par C5   la cible sca ne bloque plus
  PASS  mutant c6   détecté par C6   seuil écrit en dur au lieu d'être piloté par la variable
  PASS  mutant c7   détecté par C7   rapport SAST écrit ailleurs qu'à l'emplacement imposé
  PASS  mutant c8   détecté par C8   l'envoi du rapport peut faire échouer un job
== Étape 05
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   outil d'installation laissé dans l'image
  PASS  mutant c2   détecté par C2   le scan d'image ne bloque plus
  PASS  mutant c3   détecté par C3   socket Docker monté dans le scanner
  PASS  mutant c4   détecté par C4   configuration de l'image non analysée
  PASS  mutant c5   détecté par C5   rapport d'image écrit ailleurs qu'à l'emplacement imposé
  PASS  mutant c6   détecté par C6   le job image ne scanne plus
== Étape 06
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   la cible tf-fmt ne vérifie plus le format
  PASS  mutant c2   détecté par C2   la cible tf-validate ne valide plus
  PASS  mutant c3   détecté par C3   le plan exige des identifiants AWS
  PASS  mutant c4   détecté par C4   le rôle applicatif n'est plus créé
  PASS  mutant c5   détecté par C5   une ressource payante est ajoutée
  PASS  mutant c6   détecté par C6   fichier de verrouillage des providers absent
  PASS  mutant c7   détecté par C7   verrou d'état désactivé
  PASS  mutant c8   détecté par C8   le job de plan des PR peut demander un jeton cloud
== Étape 07
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   Trivy config ne bloque plus
  PASS  mutant c2   détecté par C2   Checkov ne bloque plus
  PASS  mutant c3   détecté par C3   policy trop stricte : elle refuse un plan conforme
  PASS  mutant c4   détecté par C4   policy S3 neutralisée
  PASS  mutant c5   détecté par C5   policy réseau neutralisée
  PASS  mutant c6   détecté par C6   un tag obligatoire n'est plus exigé
  PASS  mutant c7   détecté par C7   un type de ressource payante n'est plus interdit
  PASS  mutant c8   détecté par C8   tests unitaires des policies supprimés
  PASS  mutant c9   détecté par C9   le résultat des policies n'est plus pris en compte
  PASS  mutant c10  détecté par C10  le workflow de PR ne lance plus les policies
== Étape 08
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   le job exceptions ne vérifie plus rien
  PASS  mutant c2   détecté par C2   la cible exceptions accepte tout
  PASS  mutant c3   détecté par C3   seuil par défaut abaissé
  PASS  mutant c4   détecté par C4   le verdict peut être sauté
  PASS  mutant c5   détecté par C5   un contrôle n'est plus un prérequis du verdict
  PASS  mutant c6   détecté par C6   le verdict ne reçoit plus le résultat des jobs
  PASS  mutant c7   détecté par C7   le scan global ne renvoie plus d'échec
  PASS  mutant c8   détecté par C8   droit de commenter la PR retiré
  PASS  mutant c9   détecté par C9   titre de la PR inséré dans un script
== Étape 09
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   ruleset désactivé
  PASS  mutant c2   détecté par C2   un rôle peut contourner le ruleset
  PASS  mutant c3   détecté par C3   réécriture d'historique autorisée
  PASS  mutant c4   détecté par C4   pull request non obligatoire
  PASS  mutant c5   détecté par C5   un statut n'est plus requis
  PASS  mutant c6   détecté par C6   push protection non activée
  PASS  mutant c7   détecté par C7   le script recrée le ruleset à chaque lancement
== Étape 10
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   fournisseur d'identité pointant ailleurs que GitHub Actions
  PASS  mutant c2   détecté par C2   comparaison du sujet par motif
  PASS  mutant c2b  détecté par C2   sujet avec joker
  PASS  mutant c3   détecté par C3   condition sur l'audience retirée
  PASS  mutant c4   détecté par C4   bucket d'état sans versioning
  PASS  mutant c5   détecté par C5   alerte de budget supprimée
  PASS  mutant c6   détecté par C6   clé d'accès statique dans le workflow de déploiement
  PASS  mutant c7   détecté par C7   apply hors de tout environnement, donc sans approbation
  PASS  mutant c8   détecté par C8   déploiement déclenchable par une pull request
  PASS  mutant c9   détecté par C9   toutes les actions accordées au rôle de déploiement
  PASS  mutant c10  détecté par C10  apply sans confirmation explicite
== Étape 11
  PASS  corrigé
  PASS  squelette
  PASS  mutant c1   détecté par C1   inventaire produit dans un autre format
  PASS  mutant c2   détecté par C2   le scan de l'inventaire ne bloque plus
  PASS  mutant c3   détecté par C3   image Prowler sans digest
  PASS  mutant c4   détecté par C4   inventaire aussi produit sur les pull requests
== Progression : étapes 1 à N résolues
  PASS  N=1 : check-etape-01 passe
  PASS  N=1 : check-etape-02 échoue
  PASS  N=2 : check-etape-02 passe
  PASS  N=2 : check-etape-03 échoue
  PASS  N=3 : check-etape-03 passe
  PASS  N=3 : check-etape-04 échoue
  PASS  N=4 : check-etape-04 passe
  PASS  N=4 : check-etape-05 échoue
  PASS  N=5 : check-etape-05 passe
  PASS  N=5 : check-etape-06 échoue
  PASS  N=6 : check-etape-06 passe
  PASS  N=6 : check-etape-07 échoue
  PASS  N=7 : check-etape-07 passe
  PASS  N=7 : check-etape-08 échoue
  PASS  N=8 : check-etape-08 passe
  PASS  N=8 : check-etape-09 échoue
  PASS  N=9 : check-etape-09 passe
  PASS  N=9 : check-etape-10 échoue
  PASS  N=10 : check-etape-10 passe
  PASS  N=10 : check-etape-11 échoue
== Cohérence page / contrôle / mutant
  PASS  86 contraintes, 0 sans contrôle ou sans mutant (tableau : reports/correspondance.md)
== Fuite du corrigé
  PASS  564 lignes du corrigé cherchées dans 95 fichiers, 0 occurrence(s)
test-checks : TOUT EST VERT
```

Durée : 15 minutes, caches chauds.

## Correspondance contrainte, contrôle, mutant

| Étape | Contrainte | Énoncé | Contrôle | Mutant |
|---|---|---|---|---|
| 01 | C1 | Le workflow se déclenche sur les pull requests visant `main`, sur les … | structure (Rego) | `c1` déclenchement manuel retiré |
| 01 | C2 | Le jeton du workflow n'a aucun droit par défaut. Chaque job déclare le… | structure (Rego) | `c2` droits par défaut rendus au jeton |
| 01 | C3 | Toute action tierce est épinglée par SHA de commit complet. | structure (Rego) | `c3` une action épinglée par tag |
| 01 | C4 | Le jeton ne reste pas dans la configuration git du runner après la réc… | structure (Rego) | `c4` persistance du jeton réactivée |
| 01 | C5 | Le job n'installe aucun outil : il appelle `make lint-workflows`. | structure (Rego) | `c5` le job n'appelle plus make |
| 01 | C6 | Le rapport est publié en artifact même si le lint échoue, et conservé … | structure (Rego) | `c6` artifact non publié en cas d'échec |
| 01 | C7 | Chaque job a une durée maximale explicite. | structure (Rego) | `c7` durée maximale retirée |
| 01 | C8 | Un nouveau push sur la même référence annule l'exécution précédente. | structure (Rego) | `c8` annulation de l'exécution précédente retirée |
| 01 | C9 | `make lint-workflows` écrit sa sortie dans `reports/actionlint.txt` et… | contrôle scripté + comportement : doit réussir + comportement : doit échouer | `c9` pipefail retiré : le tube masque l'échec |
| 02 | C1 | L'image de base est épinglée par digest. | structure (Rego) | `c1` image de base sans digest |
| 02 | C2 | Le conteneur ne s'exécute pas en root : un utilisateur sans privilège … | structure (Rego) + contrôle scripté | `c2` exécution en root |
| 02 | C3 | L'image déclare un contrôle de santé. | structure (Rego) | `c3` contrôle de santé retiré |
| 02 | C4 | L'installation des dépendances ne laisse pas le cache de `pip` dans l'… | structure (Rego) | `c4` cache pip conservé dans l'image |
| 02 | C5 | `make test` lance les tests unitaires dans l'image Python de la plombe… | comportement : doit réussir + comportement : doit échouer | `c5` la cible test ne lance plus les tests |
| 02 | C6 | `make build` construit l'image dont le nom est donné par la variable `… | comportement : doit réussir + contrôle scripté | `c6` la cible build ignore la variable IMAGE |
| 02 | C7 | Le job `build-test` appelle `make test` puis `make build`. | structure (Rego) | `c7` le job build-test ne lance plus les tests |
| 03 | C1 | `make secrets` réussit sur un historique sain et échoue dès qu'un secr… | comportement : doit réussir + comportement : doit échouer | `c1` règles par défaut désactivées |
| 03 | C2 | Une règle maison, d'identifiant `lab-fake-token`, détecte le format in… | structure (Rego) + comportement : doit échouer | `c2` règle maison qui ne reconnaît plus le format du lab |
| 03 | C3 | `make secrets` analyse tout l'historique git : un secret commité puis … | comportement : doit échouer | `c3` scan du répertoire courant au lieu de l'historique |
| 03 | C4 | `make secrets` produit un rapport SARIF dans `reports/gitleaks.sarif`. | présence du rapport | `c4` rapport écrit ailleurs qu'à l'emplacement imposé |
| 03 | C5 | `make secrets-staged` n'analyse que les fichiers indexés, pas encore c… | comportement : doit réussir + comportement : doit échouer | `c5` la cible du hook ne regarde plus les fichiers indexés |
| 03 | C6 | Un hook pre-commit appelle `make secrets-staged`. | structure (Rego) | `c6` le hook appelle le scan d'historique |
| 03 | C7 | Le job `secrets` récupère tout l'historique avant d'appeler `make secr… | structure (Rego) | `c7` historique tronqué dans le job |
| 03 | C8 | La valeur d'un secret détecté n'apparaît jamais en clair dans la sorti… | contrôle scripté | `c8` secrets affichés en clair |
| 04 | C1 | `make sast` réussit sur le code fourni et échoue sur une injection SQL… | comportement : doit réussir + comportement : doit échouer | `c1` jeux de règles communautaires retirés |
| 04 | C2 | Une règle maison bloque un secret de configuration écrit en dur (une c… | comportement : doit échouer | `c2` règle maison sur les secrets de configuration retirée |
| 04 | C3 | Une règle maison bloque l'activation en dur du mode debug de Flask. | comportement : doit échouer | `c3` règle maison sur le mode debug retirée |
| 04 | C4 | Seuls les constats de sévérité `ERROR` font échouer `make sast` ; le s… | comportement : doit réussir | `c4` le SAST bloque sur toutes les sévérités |
| 04 | C5 | `make sca` réussit sur les dépendances fournies et échoue sur des dépe… | comportement : doit réussir + comportement : doit échouer | `c5` la cible sca ne bloque plus |
| 04 | C6 | Le seuil de `make sca` est piloté par la variable `TRIVY_SEVERITY`, qu… | comportement : doit réussir | `c6` seuil écrit en dur au lieu d'être piloté par la variable |
| 04 | C7 | Les rapports SARIF sont écrits dans `reports/semgrep.sarif` et `report… | présence du rapport | `c7` rapport SAST écrit ailleurs qu'à l'emplacement imposé |
| 04 | C8 | Les jobs `sast` et `sca` appellent leur cible. Tout envoi de rapport v… | structure (Rego) | `c8` l'envoi du rapport peut faire échouer un job |
| 05 | C1 | `make build image-scan` réussit sur ton image : aucune vulnérabilité `… | comportement : doit réussir | `c1` outil d'installation laissé dans l'image |
| 05 | C2 | `make image-scan` échoue sur une image construite à partir d'une base … | comportement : doit échouer + contrôle scripté | `c2` le scan d'image ne bloque plus |
| 05 | C3 | Le scanner n'a pas accès au socket Docker. | lecture du fichier | `c3` socket Docker monté dans le scanner |
| 05 | C4 | `make image-scan` échoue sur une image qui s'exécute en root : la conf… | comportement : doit échouer + contrôle scripté | `c4` configuration de l'image non analysée |
| 05 | C5 | Le rapport SARIF est écrit dans `reports/trivy-image.sarif`. | présence du rapport | `c5` rapport d'image écrit ailleurs qu'à l'emplacement imposé |
| 05 | C6 | Le job `image` appelle `make build` puis `make image-scan`. | structure (Rego) | `c6` le job image ne scanne plus |
| 06 | C1 | `make tf-fmt` réussit sur ton code et échoue sur un fichier mal format… | comportement : doit réussir + comportement : doit échouer | `c1` la cible tf-fmt ne vérifie plus le format |
| 06 | C2 | `make tf-validate` réussit sur ton code et échoue sur une référence in… | comportement : doit réussir + comportement : doit échouer | `c2` la cible tf-validate ne valide plus |
| 06 | C3 | `make plan` fonctionne sans aucun identifiant AWS et exporte le plan d… | comportement : doit réussir + présence du rapport | `c3` le plan exige des identifiants AWS |
| 06 | C4 | Le plan crée au moins : un VPC, un sous-réseau, un security group, un … | structure (Rego) | `c4` le rôle applicatif n'est plus créé |
| 06 | C5 | Le plan ne crée aucune ressource payante : ni NAT Gateway, ni instance… | structure (Rego) | `c5` une ressource payante est ajoutée |
| 06 | C6 | Le fichier de verrouillage des providers est commité dans `terraform/e… | présence du fichier | `c6` fichier de verrouillage des providers absent |
| 06 | C7 | L'état distant est déclaré dans un backend S3, chiffré, avec le verrou… | lecture du fichier + contrôle scripté | `c7` verrou d'état désactivé |
| 06 | C8 | Le workflow `terraform-plan` se déclenche sur les pull requests, appel… | structure (Rego) | `c8` le job de plan des PR peut demander un jeton cloud |
| 07 | C1 | `make iac-trivy` réussit sur ton code et échoue sur un bucket exposabl… | comportement : doit réussir + comportement : doit échouer | `c1` Trivy config ne bloque plus |
| 07 | C2 | `make iac-checkov` réussit sur ton code et échoue sur le même bucket. | comportement : doit réussir + comportement : doit échouer | `c2` Checkov ne bloque plus |
| 07 | C3 | Tes policies acceptent un plan conforme : celui de `checks/fixtures/pl… | contrôle scripté + comportement : doit réussir | `c3` policy trop stricte : elle refuse un plan conforme |
| 07 | C4 | Tes policies refusent un bucket dont l'un des quatre blocages d'accès … | contrôle scripté | `c4` policy S3 neutralisée |
| 07 | C5 | Tes policies refusent une règle d'entrée ouverte à tout Internet, en I… | contrôle scripté | `c5` policy réseau neutralisée |
| 07 | C6 | Tes policies refusent une ressource taggable à laquelle il manque l'un… | contrôle scripté | `c6` un tag obligatoire n'est plus exigé |
| 07 | C7 | Tes policies refusent la création d'une ressource payante (au minimum … | contrôle scripté | `c7` un type de ressource payante n'est plus interdit |
| 07 | C8 | `make policy-test` exécute au moins quatre tests unitaires de policies… | contrôle scripté | `c8` tests unitaires des policies supprimés |
| 07 | C9 | `make policy` calcule le plan, applique les policies à ce plan, et éch… | comportement : doit échouer | `c9` le résultat des policies n'est plus pris en compte |
| 07 | C10 | Le job `iac` lance les deux scanners ; le workflow `terraform-plan` ap… | structure (Rego) | `c10` le workflow de PR ne lance plus les policies |
| 08 | C1 | `make exceptions` réussit sur ton dépôt, et un job `exceptions` l'appe… | structure (Rego) + comportement : doit réussir | `c1` le job exceptions ne vérifie plus rien |
| 08 | C2 | `make exceptions` échoue si une exception n'a pas de date d'expiration… | comportement : doit échouer | `c2` la cible exceptions accepte tout |
| 08 | C3 | Les seuils par défaut sont ceux du lab : vulnérabilités `HIGH` et `CRI… | contrôle scripté | `c3` seuil par défaut abaissé |
| 08 | C4 | Le job `security-gate` s'exécute même quand un contrôle a échoué. | structure (Rego) | `c4` le verdict peut être sauté |
| 08 | C5 | Le job `security-gate` dépend de tous les contrôles : `workflow-lint`,… | structure (Rego) | `c5` un contrôle n'est plus un prérequis du verdict |
| 08 | C6 | `make summary` reçoit le résultat des jobs par la variable d'environne… | comportement : doit réussir + comportement : doit échouer | `c6` le verdict ne reçoit plus le résultat des jobs |
| 08 | C7 | `make scan` lance tous les contrôles en local, ne s'arrête pas au prem… | comportement : doit réussir + comportement : doit échouer + contrôle scripté | `c7` le scan global ne renvoie plus d'échec |
| 08 | C8 | Seul le job `security-gate` peut écrire sur les pull requests, et il n… | structure (Rego) | `c8` droit de commenter la PR retiré |
| 08 | C9 | Aucune donnée non fiable de la pull request (titre, description, nom d… | structure (Rego) | `c9` titre de la PR inséré dans un script |
| 09 | C1 | Le ruleset est actif et vise la branche par défaut. | structure (Rego) | `c1` ruleset désactivé |
| 09 | C2 | Personne ne peut le contourner : la liste des acteurs exemptés est vid… | structure (Rego) | `c2` un rôle peut contourner le ruleset |
| 09 | C3 | La branche ne peut être ni supprimée, ni réécrite par un push forcé. | structure (Rego) | `c3` réécriture d'historique autorisée |
| 09 | C4 | Toute modification passe par une pull request. | structure (Rego) | `c4` pull request non obligatoire |
| 09 | C5 | La fusion exige les statuts `security-gate` et `plan`, sur une branche… | structure (Rego) | `c5` un statut n'est plus requis |
| 09 | C6 | Le script applique le fichier de ruleset versionné et active la protec… | présence du fichier + contrôle scripté + lecture du fichier | `c6` push protection non activée |
| 09 | C7 | Le script est rejouable : relancé, il met à jour le ruleset existant a… | lecture du fichier | `c7` le script recrée le ruleset à chaque lancement |
| 10 | C1 | Le bootstrap se planifie hors ligne et crée un fournisseur d'identité … | structure (Rego) + contrôle scripté | `c1` fournisseur d'identité pointant ailleurs que GitHub Actions |
| 10 | C2 | La politique de confiance des rôles compare le sujet du jeton en égali… | lecture du fichier | `c2` comparaison du sujet par motif ; `c2b` sujet avec joker |
| 10 | C3 | L'audience du jeton est vérifiée : seule celle d'AWS STS est acceptée. | lecture du fichier + structure (Rego) | `c3` condition sur l'audience retirée |
| 10 | C4 | Le bucket d'état est versionné, chiffré, et bloque tout accès public. | structure (Rego) | `c4` bucket d'état sans versioning |
| 10 | C5 | Une alerte de budget est créée. | structure (Rego) | `c5` alerte de budget supprimée |
| 10 | C6 | Aucune clé d'accès AWS statique n'apparaît dans un workflow : les jobs… | structure (Rego) + lecture du fichier | `c6` clé d'accès statique dans le workflow de déploiement |
| 10 | C7 | Tout job qui obtient des identifiants AWS s'exécute dans un environnem… | structure (Rego) | `c7` apply hors de tout environnement, donc sans approbation |
| 10 | C8 | Le déploiement ne peut pas être déclenché par une pull request ; en au… | structure (Rego) | `c8` déploiement déclenchable par une pull request |
| 10 | C9 | Aucune politique du bootstrap n'accorde toutes les actions. | lecture du fichier | `c9` toutes les actions accordées au rôle de déploiement |
| 10 | C10 | `make aws-apply` et `make aws-destroy` refusent de s'exécuter sans la … | contrôle scripté | `c10` apply sans confirmation explicite |
| 11 | C1 | `make sbom` produit l'inventaire de l'image au format CycloneDX dans `… | comportement : doit réussir + contrôle scripté | `c1` inventaire produit dans un autre format |
| 11 | C2 | `make sbom-scan` cherche les vulnérabilités à partir de l'inventaire s… | comportement : doit réussir + comportement : doit échouer + contrôle scripté | `c2` le scan de l'inventaire ne bloque plus |
| 11 | C3 | L'image de Prowler est épinglée par digest. | contrôle scripté | `c3` image Prowler sans digest |
| 11 | C4 | Le job `sbom` ne s'exécute pas sur les pull requests, appelle `make sb… | structure (Rego) | `c4` inventaire aussi produit sur les pull requests |
