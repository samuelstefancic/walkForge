# AGENTS STATE — WalkForge

État en temps réel des agents multi-agent. Mis à jour à chaque livrable.

---

## 🎛️ Orchestrateur

- **Statut** : actif
- **Sprint en cours** : Sprint 3 — Data + Notifications + Maintenance
- **Sprints précédents** : ✅ Sprint 1 (`cc71b9e`), ✅ Sprint 2 (`83b5473`)
- **Bloquants** : aucun
- **Prochaine étape** : Sprint 4 (Historique + HealthKit + Widgets)

---

## Sprint 1 (✅ mergé) — Livrables

| Agent          | Livrable                                                          | Tests  |
| -------------- | ----------------------------------------------------------------- | ------ |
| Agent-BLE      | `BLECore` (FTMS parser, `BLEManager`, `MockBLEManager`)           | 38 ✅  |
| Agent-Domain   | `DomainKit` entités + protocols + errors                          | 12 ✅  |

## Sprint 2 (✅ mergé) — Livrables

| Agent          | Livrable                                                          | Tests  |
| -------------- | ----------------------------------------------------------------- | ------ |
| Agent-Domain   | 5 use cases session                                                | 19 ✅ |
| Agent-UI       | `DesignSystem` + 5 composants                                      | 1 ✅  |
| Agent-Session  | App iOS + Dashboard                                                | —     |

## Sprint 3 — Agents actifs

| Agent          | Statut   | Livrable                                                          | Tests  |
| -------------- | -------- | ----------------------------------------------------------------- | ------ |
| Agent-Domain   | ✅ livré | 3 use cases (`MaintenanceAlert`, `MotorRestAlert`, `PersistSession`) + `NotificationServiceProtocol` | 8 ✅  |
| Agent-Data     | ✅ livré | `DataKit` — 4 `@Model` SwiftData + 3 repositories `@ModelActor`     | 13 ✅ |
| Agent-Infra    | ✅ livré | `NotificationKit` — `UserNotificationsService` + mapper            | 5 ✅  |
| Agent-Profile  | ✅ livré | `ProfileView` (mensurations + objectifs + maintenance), `ProgramsView` (liste + création rapide) | —     |
| Agent-Session  | ✅ livré | `DashboardViewModel` persistence + motor-rest alert + `AppServices` + `MainTabView` | —     |
| Agent-Reviewer | ⏳       | Review Swift 6 strict complete + 0 lint violation                  | —     |
| Agent-Security | ⏳       | Audit : ZERO donnée perso loggée, pas de KC avant S5              | —     |

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
