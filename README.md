# Banc de test des vérifications du parcours

> [!IMPORTANT]
> Cette branche décrit le corrigé : chaque mutant en retire une contrainte précise. **Ne l'ouvre pas avant d'avoir fini le parcours.** Elle n'est jamais copiée dans le dépôt d'un apprenant.

Le banc lit le squelette et ses vérifications sur la branche `exercices`, et le corrigé sur la branche `solution`. Il ne contient ni l'un ni l'autre.

## Ce qu'il vérifie

| Partie | Ce qui est éprouvé |
|---|---|
| Corrigé et squelette | Chaque `check-etape-XX` passe sur le corrigé et échoue sur le squelette |
| Mutants | Chaque mutant retire une contrainte du corrigé ; la vérification doit échouer **en citant cette contrainte** |
| Progression | Avec les étapes 1 à N résolues, la vérification N passe et la N+1 échoue |
| Cohérence | Chaque contrainte numérotée d'une page a au moins un contrôle et un mutant |
| Fuite | Aucun fragment du corrigé sur `exercices` qui ne soit imposé par un énoncé ou justifié par un contrôle |
| Séparation | Aucun fichier ni cible de mainteneur sur `exercices` |

## Lancer

Prérequis : Docker, `make`, `bash`, `git`, `python3`.

```bash
git clone https://github.com/Gachtout/Lab-CI-CD.git && cd Lab-CI-CD
git switch banc
make test-checks                              # tout : 15 à 60 minutes selon les caches
make fuites                                   # cohérence et fuite seulement : quelques secondes
make test-checks STEPS="03" PARTS=mutants     # une étape
```

Par défaut, le banc lit `origin/exercices` et `origin/solution`. Pour tester un travail en cours : `EXERCICES_DIR=/chemin/vers/exercices make test-checks`, ou `EXERCICES_REF=ma-branche`.

Rapports produits dans `reports/` : `correspondance.md` (contrainte, contrôle, mutant) et `fuites.md` (chaque fragment du corrigé trouvé, classé et justifié).

## Organisation

| Chemin | Rôle |
|---|---|
| `mutants/etape_NN.py` | Les mutants de l'étape : des transformations appliquées à la volée au corrigé, jamais des fichiers complets |
| `tools/mut.py` | Applique un mutant dans une copie du corrigé |
| `tools/slice.py` | Reconstitue un dépôt où seules les étapes 1 à N sont résolues |
| `tools/coherence.py` | Tableau de correspondance entre pages, contrôles et mutants |
| `tools/leak.py` | Recherche de fuite, avec classement |
| `tools/leak-allow.tsv` | Fragments tolérés dans `checks/`, chacun avec sa justification |
| `tools/test-checks.sh` | Enchaîne le tout |

## Recherche de fuite : méthode et limites

`leak.py` extrait du corrigé les lignes entières (30 caractères et plus), puis les littéraux de 12 caractères et plus : chaînes entre guillemets, options de commande avec leur valeur, valeurs YAML, noms de clés et d'attributs, jetons à ponctuation technique, noms de fichiers. Il les cherche dans tous les fichiers d'`exercices`, y compris après dés-échappement des expressions régulières. Il cherche en plus, dans les pages, tout extrait entre accents graves présent tel quel dans le corrigé.

Chaque occurrence est classée : faute injectée, donnée d'entrée, énoncé ou contrat, nécessaire au check (justification obligatoire), ou fuite. Une seule fuite fait échouer le banc.

Ce que la méthode ne voit pas :

- une reformulation en prose d'un choix du corrigé (un indice de niveau 3 qui décrit la réponse sans la citer) ;
- un fragment de moins de 12 caractères hors des pages ;
- ce qu'un contrôle révèle par sa seule logique : une vérification qui cherche un champ dit que ce champ est attendu. La classe « nécessaire au check » est donc une divulgation assumée, pas une absence de divulgation.
