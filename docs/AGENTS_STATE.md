# AGENTS STATE — WalkForge

État en temps réel des agents multi-agent. Mis à jour à chaque livrable.

---

## 🎛️ Orchestrateur

- **Statut** : actif
- **Sprint en cours** : Sprint 2 — Contrôle vitesse + Session live
- **Sprint précédent** : ✅ Sprint 1 mergé (commit `cc71b9e`)
- **Bloquants** : aucun
- **Prochaine étape** : Sprint 3 (notifications, programmes, maintenance)

---

## Sprint 1 (✅ mergé) — Livrables

| Agent          | Livrable                                                          | Tests  |
| -------------- | ----------------------------------------------------------------- | ------ |
| Agent-BLE      | `BLECore` (FTMS parser, `BLEManager`, `MockBLEManager`)           | 38 ✅  |
| Agent-Domain   | `DomainKit` entités + protocols + errors                          | 12 ✅  |

## Sprint 2 — Agents actifs

| Agent          | Statut   | Livrable                                                          | Tests  |
| -------------- | -------- | ----------------------------------------------------------------- | ------ |
| Agent-Domain   | ✅ livré | 5 use cases (StartSession, StopSession, SetTargetSpeed, SetIncline, CalculateCalories) | 19 ✅ |
| Agent-UI       | ✅ livré | `DesignSystem` (palette, typography, spacing, haptics, 5 composants)                   | 1 ✅   |
| Agent-Session  | ✅ livré | App iOS + `DashboardViewModel` + `DashboardView`                  | —      |
| Agent-Reviewer | ⏳       | Checklist Clean Architecture + Swift 6 strict concurrency         | —      |
| Agent-Security | ⏳       | Audit : pas de données perso en logs, no force unwrap             | —      |

---

## Sprints suivants (scaffold)

- Sprint 3 : Agent-Infra (notifications), Agent-Data (SwiftData + repositories), Agent-Profile, Agent-Security
- Sprint 4 : Agent-History, Agent-Infra (HealthKit), Agent-Widgets, Agent-Accessibility
- Sprint 5 : Agent-Reviewer, Agent-Security, Agent-Tests (audit final + Apple Developer Program + TestFlight)

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
