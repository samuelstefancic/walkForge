## Contexte

<!-- Sprint + Agent concerné (ex: "Sprint 1 · Agent-BLE") -->

## Changements

<!-- Liste des changements majeurs en bullet points. Pas de prose. -->

-

## Checklist Agent-Reviewer

- [ ] Respect Clean Architecture (dépendances vers l'intérieur uniquement)
- [ ] Swift 6.2 strict concurrency — 0 warning `Sendable` / `@MainActor`
- [ ] Pas de `print()` en code prod (utiliser `os.Logger`)
- [ ] Pas de force unwrap (`!`) sans commentaire de justification
- [ ] Gestion d'erreurs exhaustive (`do/catch` typé ou `Result<>`)
- [ ] Tests unitaires présents pour chaque nouvelle API publique
- [ ] DocC `///` sur toutes les API publiques
- [ ] `swiftlint --strict` = 0 violation
- [ ] `swiftformat --lint .` = 0 diff

## Checklist Agent-Security (si BLE / HealthKit / données perso)

- [ ] Aucune donnée sensible loggée
- [ ] Bounds checking sur toutes les données BLE reçues
- [ ] Permissions HealthKit demandées granulairement
- [ ] Pas de clé API ou secret dans le code

## Tests

<!-- Résumé : combien de tests ajoutés, coverage approximatif, tests manuels -->

## Impacts inter-agents

<!-- Modifier une interface publique de DomainKit ? Lister les agents à notifier. -->
