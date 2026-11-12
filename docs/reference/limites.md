# Limites : ce que ces outils ne font pas, face à Wiz

Ce lab reproduit la partie **pipeline** d'un outil comme Wiz. Il ne reproduit pas ce qui fait sa valeur principale. Cette page existe pour ne pas survendre le résultat.

## 1. Aucun contexte cloud

Chaque outil juge un fichier isolé. Trivy signale une CVE `HIGH` dans une image sans savoir si cette image tourne, si elle est joignable depuis Internet, ni quelles données son rôle peut lire. Le résultat : une liste longue et plate, où l'urgent et l'anodin ont la même couleur.

Wiz relie la vulnérabilité à la ressource déployée, à son exposition réseau effective et à ses permissions. La priorisation change du tout au tout.

## 2. Pas de graphe, donc pas de combinaisons toxiques

Une combinaison toxique est un ensemble de faiblesses individuellement tolérables qui, réunies, forment un chemin d'attaque : une machine exposée à Internet, **et** porteuse d'une vulnérabilité exploitable, **et** dotée d'un rôle qui lit un bucket de données sensibles.

Les policies de ce lab regardent une ressource à la fois. Écrire en Rego la règle « exposé ET vulnérable ET privilégié » demanderait de reconstruire le graphe des relations du compte, c'est-à-dire de réécrire le cœur du produit.

## 3. Rien à l'exécution

Tous les contrôles s'arrêtent à la fusion (ou au moment où l'on lance Prowler). Le lab ne voit pas un processus anormal dans un conteneur, une connexion sortante suspecte, ni l'usage réel d'un secret volé. Il ne sait pas non plus si une bibliothèque vulnérable est effectivement chargée en mémoire.

## 4. Pas de scan continu

Une image verte aujourd'hui sera vulnérable demain, sans qu'aucun pipeline ne tourne. Le SBOM de l'étape 11 permet de re-scanner, mais il faut y penser et l'automatiser. Wiz re-évalue en permanence ce qui est déployé.

## 5. Couverture limitée à ce que Terraform gère

Une ressource créée à la console n'existe pas pour le pipeline. Prowler la voit, mais seulement quand on le lance, et sans la relier à quoi que ce soit.

## 6. Analyse statique incomplète

Lire le code n'est pas lire le résultat : un scanner statique doit reconstituer les valeurs que Terraform ne calcule qu'au moment du plan. Tu le constateras toi-même à l'[étape 7](../etapes/07-iac-policies.md).

## 7. Détection de secrets par format uniquement

Gitleaks trouve ce qui ressemble à un secret. Il ne dit pas si le secret est valide, ni ce qu'il ouvre. Un mot de passe faible et lisible passe au travers ([étape 3](../etapes/03-secrets.md)).

## 8. Gouvernance dans le dépôt

Seuils, exceptions et policies vivent dans le dépôt : une PR peut les modifier ([étape 9](../etapes/09-branch-protection.md)). Avec Wiz, ils sont dans une console, sous contrôle d'accès, avec un historique. Il n'y a ici ni tableau de bord transverse, ni suivi des délais de correction, ni attribution d'un constat à une équipe.

## 9. Six outils, six formats

Chaque outil a ses identifiants de règles, ses sévérités et son format d'exception. Un même défaut (bucket public) sort sous trois noms. Le script de synthèse agrège, il ne dédoublonne pas.

## Ce que le lab fait bien malgré tout

- Bloquer avant la fusion les défauts évidents, gratuitement.
- Rendre chaque mécanisme lisible : rien n'est caché derrière une console.
- Enseigner ce qui ne dépend pas de l'outil : seuils, exceptions, statuts requis, OIDC, moindre privilège.

Un outil comme Wiz ne dispense d'aucun de ces trois points. Il rend la décision meilleure ; il ne construit pas la chaîne à ta place.
