# WalkForge

Application iOS native pour piloter un tapis de marche de bureau via Bluetooth Low Energy — protocole **FTMS (Fitness Machine Service, UUID `0x1826`)**.

Matériel cible initial : **PORTENTUM Treadmill 8 Pro**.

## Stack

| Composant      | Choix                                                    |
| -------------- | -------------------------------------------------------- |
| Langage        | Swift 6.2 (strict concurrency)                           |
| UI             | SwiftUI + `@Observable`                                  |
| Concurrency    | `async/await`, `Actor`, `AsyncStream`                    |
| Persistance    | SwiftData (CoreData pour la migration legacy)            |
| BLE            | CoreBluetooth — FTMS (`0x1826`)                          |
| Santé          | HealthKit (`HKWorkout`, fréquence cardiaque, calories)   |
| Widgets        | WidgetKit — Lock Screen + Dynamic Island + Home Screen   |
| Documentation  | DocC                                                     |
| Lint / Format  | SwiftLint (strict) + SwiftFormat                         |
| CI             | GitHub Actions (macOS)                                   |
| iOS minimum    | 18.0                                                     |

## Architecture

Clean Architecture à 3 couches, modules SPM séparés :

```
walkForge/
├── App/                          # Cible iOS (ajoutée au Sprint 2)
├── Packages/
│   ├── BLECore/                  # CoreBluetooth + parser FTMS
│   ├── DomainKit/                # Entités + Use Cases + Protocols (pure Swift)
│   ├── DataKit/                  # SwiftData + repositories (Sprint 3)
│   ├── HealthKitBridge/          # Intégration HealthKit (Sprint 4)
│   ├── DesignSystem/             # Palette, composants (Sprint 2)
│   ├── NotificationKit/          # UserNotifications (Sprint 3)
│   └── WidgetExtension/          # Widgets (Sprint 4)
├── WatchApp/                     # Scaffold watchOS (Sprint 5)
├── docs/
│   ├── CLAUDE.md                 # Prompt orchestrateur multi-agent
│   ├── AGENTS_STATE.md           # État des agents
│   └── ARCHITECTURE.md           # Décisions architecturales
└── .github/workflows/ci.yml      # Build + tests + lint
```

## Sprints

- [x] **Sprint 1** — Fondations BLE + Infrastructure (parser FTMS, MockBLE, protocols domaine, CI)
- [ ] **Sprint 2** — Contrôle vitesse + Session live
- [ ] **Sprint 3** — Notifications + Programmes + Maintenance
- [ ] **Sprint 4** — Historique + HealthKit + Widgets
- [ ] **Sprint 5** — Polish, CI/CD complet, App Store

Voir [`docs/CLAUDE.md`](docs/CLAUDE.md) pour le prompt orchestrateur complet.

## Développement local

### Prérequis

- macOS 15+
- Xcode 26+
- Swift 6.2
- SwiftLint + SwiftFormat : `brew install swiftlint swiftformat xcbeautify`

### Build + tests

Chaque module SPM est indépendant :

```bash
# DomainKit
cd Packages/DomainKit && swift test

# BLECore
cd Packages/BLECore && swift test
```

### Lint

```bash
swiftlint --strict
swiftformat --lint .
```

## Licence

Apache 2.0 — voir [LICENSE](LICENSE).
