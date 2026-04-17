# AGENTS STATE — WalkForge

État en temps réel des agents multi-agent. Mis à jour à chaque livrable.

---

## 🎛️ Orchestrateur

- **Statut** : actif
- **Sprint en cours** : Sprint 1 — Fondations BLE + Infrastructure
- **Bloquants** : aucun
- **Prochaine étape** : validation Sprint 1 → Sprint 2 (UI + use cases session)

---

## Sprint 1 — Agents actifs

| Agent          | Statut   | Livrable                                                        | Review |
| -------------- | -------- | --------------------------------------------------------------- | ------ |
| Agent-BLE      | ✅ livré | `BLECore` (FTMS parser, `BLEManager`, `MockBLEManager`)         | ⏳     |
| Agent-Domain   | ✅ livré | `DomainKit` (entités + protocols + errors)                      | ⏳     |
| Agent-Tests    | ✅ livré | Tests unitaires FTMS parser + MockBLE                           | ⏳     |
| Agent-DocC     | ✅ livré | Commentaires `///` sur API publiques                            | ⏳     |
| Agent-Reviewer | ⏳       | Checklist Clean Architecture + Swift 6 strict concurrency       | —      |
| Agent-Security | ⏳       | Audit BLE (bounds checking, logs, données sensibles)            | —      |

---

## Sprints suivants (scaffold)

- Sprint 2 : Agent-Session, Agent-UI, Agent-Domain (use cases), Agent-Reviewer
- Sprint 3 : Agent-Infra (notifications), Agent-Profile, Agent-Security
- Sprint 4 : Agent-History, Agent-Infra (HealthKit), Agent-Widgets, Agent-Accessibility
- Sprint 5 : Agent-Reviewer, Agent-Security, Agent-Tests (audit final)

---

## Interfaces partagées (contrat inter-agents)

Tous les protocols publics sont définis dans `DomainKit` :

- `BLETreadmillServiceProtocol` — implémenté par `BLECore.BLEManager` et `BLECore.MockBLEManager`
- `WorkoutSessionRepository` — à implémenter par `DataKit` au Sprint 3
- `UserProfileRepository` — à implémenter par `DataKit` au Sprint 3
- `SessionProgramRepository` — à implémenter par `DataKit` au Sprint 3
- `HealthKitServiceProtocol` — à implémenter par `HealthKitBridge` au Sprint 4
- `NotificationServiceProtocol` — à implémenter par `NotificationKit` au Sprint 3

Toute modification d'interface publique requiert notification à l'Orchestrateur et mise à jour de ce document.
