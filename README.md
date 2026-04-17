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
├── project.yml                   # Définition Xcode project (XcodeGen)
├── App/                          # Cible iOS 18+
│   ├── WalkForgeApp.swift
│   ├── Views/                    # Dashboard, futurs écrans
│   ├── ViewModels/               # @Observable (framework Observation)
│   └── Resources/                # Assets.xcassets (icônes, couleurs)
├── Packages/
│   ├── BLECore/                  # CoreBluetooth + parser FTMS (Sprint 1)
│   ├── DomainKit/                # Entités + Use Cases + Protocols (Sprint 1-2)
│   ├── DesignSystem/             # Palette + composants SwiftUI (Sprint 2)
│   ├── DataKit/                  # SwiftData + repositories (Sprint 3 ✅)
│   ├── NotificationKit/          # UserNotifications (Sprint 3 ✅)
│   ├── HealthKitBridge/          # Intégration HealthKit (Sprint 4)
│   └── WidgetExtension/          # Widgets (Sprint 4)
├── WatchApp/                     # Scaffold watchOS (Sprint 5)
├── docs/
│   ├── CLAUDE.md                 # Prompt orchestrateur multi-agent
│   ├── AGENTS_STATE.md           # État des agents
│   └── ARCHITECTURE.md           # Décisions architecturales
└── .github/workflows/ci.yml      # Lint + tests + build iOS Simulator
```

## Sprints

- [x] **Sprint 1** — Fondations BLE + Infrastructure (parser FTMS, MockBLE, protocols domaine, CI)
- [x] **Sprint 2** — Contrôle vitesse + Session live (use cases, DesignSystem, iOS app, Dashboard)
- [x] **Sprint 3** — Notifications + Programmes + Maintenance (DataKit/SwiftData, NotificationKit, Profile, Programs, TabView)
- [ ] **Sprint 4** — Historique + HealthKit + Widgets
- [ ] **Sprint 5** — Polish, CI/CD complet, App Store

Voir [`docs/CLAUDE.md`](docs/CLAUDE.md) pour le prompt orchestrateur complet.

## Développement local

### Prérequis

- macOS 15+
- Xcode 26+
- Swift 6.2
- Tooling : `brew install swiftlint swiftformat xcbeautify xcodegen`

### Générer le projet Xcode

Le `WalkForge.xcodeproj` est **généré** à partir de `project.yml` (non versionné) :

```bash
xcodegen generate
open WalkForge.xcodeproj
```

### Build + tests

```bash
# Packages SPM (tests isolés, rapides)
cd Packages/DomainKit      && swift test
cd Packages/BLECore        && swift test
cd Packages/DesignSystem   && swift test
cd Packages/DataKit        && swift test
cd Packages/NotificationKit && swift test

# App iOS (simulator, pas besoin de signature)
xcodebuild -project WalkForge.xcodeproj -scheme WalkForge \
    -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
    CODE_SIGNING_ALLOWED=NO build
```

### Lint

```bash
swiftlint --strict
swiftformat --lint .
```

## Licence

Apache 2.0 — voir [LICENSE](LICENSE).
