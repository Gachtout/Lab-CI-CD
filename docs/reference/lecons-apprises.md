# Leçons apprises

Ces constats viennent de la construction du lab. Chacun correspond à quelque chose qui a réellement mal tourné ou surpris, avec la sortie qui le prouve dans la page d'étape citée.

## Sur les scanners

**Un scanner vert ne prouve pas l'absence du défaut.** Trivy et Checkov ont laissé passer un security group ouvert au monde, parce que la plage venait d'une variable et d'un `for_each`. La policy sur le plan l'a attrapé. Il faut savoir ce que chaque outil est capable de voir. → [Étape 7](../etapes/07-iac-policies.md)

**Une image « propre » ne l'était pas.** Base récente, épinglée par digest, non-root : sept CVE `HIGH` au premier scan. Cinq venaient de bibliothèques embarquées par `pip`, absentes de `requirements.txt`. → [Étape 5](../etapes/05-image.md)

**Épingler par digest fige aussi les failles.** L'immuabilité protège contre la substitution, pas contre le vieillissement. Il faut appliquer les correctifs au build et monter le digest régulièrement.

**Un scanner de secrets cherche des formats, pas des secrets.** Dans l'ancien lab, le job « secrets » était vert sur une application pleine de mots de passe en dur : aucun n'avait de format reconnaissable. Même la clé d'exemple d'AWS est volontairement ignorée. → [Étape 0](../00-audit.md), [Étape 3](../etapes/03-secrets.md)

**Sans filtre, le bruit noie tout.** 201 entrées dans le rapport de l'image saine avant d'aligner le rapport sur le seuil. → [ADR 0003](../adr/0003-gates-et-exceptions.md)

## Sur la mécanique de CI

**Un tube peut masquer un échec.** `make policy | tee fichier` renvoie le code de `tee`, donc `0`. Le shell par défaut d'une étape `run` n'active pas `pipefail` ; il faut déclarer `shell: bash`. Le défaut a été vu avant d'atteindre la CI, par relecture. Un gate qui ne peut pas échouer est pire qu'une absence de gate.

**Un job sauté n'est pas un job en échec.** D'où le `if: always()` du `security-gate` et le traitement de tout résultat autre que `success` comme bloquant. → [Étape 8](../etapes/08-quality-gates.md)

**Il faut tester les contrôles eux-mêmes.** `make demo-bad` vérifie que chaque faille de référence est toujours détectée. Sans cela, un changement de version ou d'option peut désarmer un gate sans que personne ne le remarque.

**Docker Hub limite le débit.** Plusieurs `429 Too Many Requests` pendant la construction. Les registres alternatifs et la variable `DOCKERHUB` viennent de là. → [ADR 0001](../adr/0001-architecture.md)

**Publier un rapport n'est pas un contrôle.** Première exécution réelle sur GitHub : cinq jobs rouges alors que tous les scans passaient. Le dépôt était privé, Code Scanning indisponible, et l'envoi du SARIF faisait échouer le job. L'envoi est désormais en `continue-on-error`, avec la permission `actions: read` qu'il exige sur un dépôt privé. Aucun test local ne pouvait le révéler.

## Sur la méthode

**Vérifier en exécutant.** L'audit de l'ancien lab a trouvé, par exécution, une route d'injection SQL qui plantait au lieu d'être exploitable, et une protection de branche qui autorisait le push direct. Aucun des deux n'était visible à la lecture.

**Attention aux tests destructifs.** Un `git reset --hard` de test a effacé un bloc du `Makefile` non commité. Les essais de casse se font désormais dans un clone temporaire.

**Dire ce qui n'a pas été testé.** Les étapes 9 et 10 ont été écrites sans dépôt GitHub ni compte AWS. Elles sont marquées comme telles plutôt que présentées comme acquises.

## À compléter après les points de contrôle

- [ ] Message exact du refus d'un push direct sur `main`.
- [ ] Comportement réel de la push protection sur un faux jeton.
- [ ] Liste des `AccessDenied` rencontrés au premier `apply`, et l'action ajoutée pour chacun.
- [ ] Durée réelle du pipeline sur les runners GitHub.
- [ ] Ce que Prowler remonte sur un compte neuf.
