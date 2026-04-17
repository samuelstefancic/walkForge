# 🏃 CLAUDE CODE — PROMPT ORCHESTRATEUR MULTI-AGENT

## Application iOS : Contrôle FTMS/BLE Tapis de Marche Bureau

### Matériel cible : PORTENTUM Treadmill 8 Pro (BLE FTMS 0x1826)

---

## 🎯 CONTEXTE PROJET

Tu es l'**Agent Orchestrateur** d'un système multi-agent Claude Code chargé de construire une application iOS native de qualité App Store. Cette application contrôle un tapis de marche de bureau via Bluetooth Low Energy (BLE) en utilisant le protocole standard **FTMS (Fitness Machine Service, UUID 0x1826)**.

L'utilisateur est un développeur Full-Stack expérimenté (Java/Spring Boot, Angular, CQRS/Event Sourcing), familier avec les architectures avancées. Il attend un code production-grade, des décisions architecturales justifiées, et une qualité irréprochable sur chaque ligne livrée.

---

## 📱 NOM DE L'APP — VALIDÉ

**WalkForge** — walk + forge (construire ses sessions).

Bundle ID : `com.samuel.walkforge`.

---

## 🛠️ STACK TECHNIQUE COMPLÈTE

| Composant | Choix |
|---|---|
| **Langage** | Swift 6.2 — strict concurrency activée |
| **UI** | SwiftUI + `@Observable` macro (framework Observation) |
| **Concurrency** | Swift structured concurrency (`async/await`, `Actor`, `AsyncStream`) |
| **Data primaire** | SwiftData (iOS 18+) |
| **Data legacy/migration** | CoreData (couche de compatibilité + migration future) |
| **BLE** | CoreBluetooth — protocole FTMS (UUID 0x1826) |
| **Santé** | HealthKit — `HKWorkout`, `HKQuantityType`, fréquence cardiaque |
| **Widgets** | WidgetKit — Lock Screen + Dynamic Island + Home Screen |
| **Notifications** | UserNotifications framework |
| **Documentation** | DocC complet (navigable dans Xcode) |
| **Linting** | SwiftLint (règles strictes) |
| **Formatage** | SwiftFormat (automatique pre-commit) |
| **CI/CD** | GitHub Actions + Xcode Cloud (Sprint 5) |
| **Distribution** | TestFlight → App Store (Sprint 5) |
| **iOS minimum** | **iOS 18.0** |

---

## 🔢 RÉFÉRENCE FTMS — OPCODES OFFICIELS (Bluetooth SIG)

> ⚠️ Le prompt v1 contenait des opcodes incohérents. La spec officielle Bluetooth SIG fait foi.

### Service + Caractéristiques (UUIDs 16 bits)

| Élément                         | UUID    | Propriété              |
| ------------------------------- | ------- | ---------------------- |
| Fitness Machine Service         | `1826`  | —                      |
| Fitness Machine Feature         | `2ACC`  | Read                   |
| Treadmill Data                  | `2ACD`  | Notify                 |
| Fitness Machine Control Point   | `2AD9`  | Write + Indicate       |
| Fitness Machine Status          | `2ADA`  | Notify                 |

### Control Point OpCodes

| Code     | Opération                    | Operands                                      |
| -------- | ---------------------------- | --------------------------------------------- |
| `0x00`   | Request Control              | —                                             |
| `0x01`   | Reset                        | —                                             |
| `0x02`   | Set Target Speed             | `uint16` LE, 0.01 km/h                        |
| `0x03`   | Set Target Inclination       | `int16`  LE, 0.1 %                            |
| `0x07`   | Start or Resume              | —                                             |
| `0x08`   | Stop or Pause                | `uint8`  (`0x01` = Stop, `0x02` = Pause)      |
| `0x80`   | Response Code (indication)   | op echo + result code                         |

### Result Codes

| Code   | Signification             |
| ------ | ------------------------- |
| `0x01` | Success                   |
| `0x02` | Op Code Not Supported     |
| `0x03` | Invalid Parameter         |
| `0x04` | Operation Failed          |
| `0x05` | Control Not Permitted     |

### Treadmill Data — flags (uint16 LE, bits de poids faible)

| Bit | Champ                      | Taille / Résolution       |
| --- | -------------------------- | ------------------------- |
| 0   | More Data (`0` ⇒ Speed présente) | —                   |
| 1   | Average Speed              | uint16 · 0.01 km/h        |
| 2   | Total Distance             | uint24 · 1 m              |
| 3   | Inclination + Ramp Angle   | int16 · 0.1 % + int16 · 0.1 ° |
| 4   | Elevation Gain +/-         | 2 × uint16 · 1 m          |
| 5   | Instantaneous Pace         | uint8  · 1 s/km           |
| 6   | Average Pace               | uint8  · 1 s/km           |
| 7   | Expended Energy            | uint16 + uint16 + uint8   |
| 8   | Heart Rate                 | uint8  · 1 bpm            |
| 9   | Metabolic Equivalent       | uint8  · 0.1              |
| 10  | Elapsed Time               | uint16 · 1 s              |
| 11  | Remaining Time             | uint16 · 1 s              |
| 12  | Force on Belt / Power      | int16 · 1 N + int16 · 1 W |

Ordre des champs dans la payload : Flags, puis champs présents dans l'ordre des bits croissants.

---

## 🏗️ ARCHITECTURE — Clean Architecture stricte

```
┌─────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                 │
│  SwiftUI Views · ViewModels (@Observable) · Widgets  │
├─────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                      │
│  Use Cases · Entities · Repository Protocols         │
├─────────────────────────────────────────────────────┤
│                     DATA LAYER                       │
│  BLE Repository · SwiftData Repository               │
│  HealthKit Repository · Notification Repository      │
└─────────────────────────────────────────────────────┘
```

Règle d'or : **les dépendances pointent toujours vers l'intérieur** (Data → Domain, Presentation → Domain). Le Domain ne dépend de personne.

---

## 🤖 SYSTÈME MULTI-AGENT

Voir [`AGENTS_STATE.md`](AGENTS_STATE.md) pour l'état en temps réel des agents.

### Agents de couche technique

- **Agent-BLE** (`BLECore`) — CoreBluetooth + parser FTMS + Mock
- **Agent-Data** (`DataKit`) — SwiftData + CoreData + repositories
- **Agent-Domain** (`DomainKit`) — Use Cases + Entities + Protocols
- **Agent-UI** (`DesignSystem` + Views) — SwiftUI + palette + composants
- **Agent-Infra** (`HealthKitBridge` + `NotificationKit`) — HealthKit + Notifications + Background

### Agents feature

- **Agent-Session** — Dashboard live + Live Activity
- **Agent-History** — Historique + Charts + export CSV
- **Agent-Profile** — Profil utilisateur + maintenance
- **Agent-Widgets** — 3 types de widgets

### Agents qualité & sécurité

- **Agent-Reviewer** — Checklist Clean Architecture, Swift 6 strict, tests
- **Agent-Security** — Audit sécurité (BLE, HealthKit, données perso)
- **Agent-Tests** — Couverture 80%+ sur DomainKit + BLECore
- **Agent-DocC** — Documentation DocC par module
- **Agent-Accessibility** — VoiceOver, Dynamic Type, WCAG AA

---

## 📋 SPRINTS

### Sprint 1 — Fondations BLE + Infrastructure ✅ **EN COURS**

Livrables :
1. Structure projet SPM (`Packages/BLECore`, `Packages/DomainKit`)
2. `BLECore` : parser FTMS + `BLEManager` + `MockBLEManager` + `AsyncStream<TreadmillData>`
3. `DomainKit` : entités + protocols repository (contrat inter-agents)
4. Tests unitaires parser FTMS + MockBLE
5. CI GitHub Actions (build + test + lint)
6. Audit sécurité BLE préliminaire

**Critère de sortie** : MockBLE fonctionnel sur simulateur, parser FTMS validé par tests unitaires avec trames binaires réelles.

### Sprint 2 — Contrôle vitesse + Session live

Use cases session, dashboard SwiftUI, DesignSystem, Live Activity.

### Sprint 3 — Notifications + Programmes + Maintenance

NotificationKit, programmes, profil, alerte lubrification 3 semaines, pause moteur 90 min.

### Sprint 4 — Historique + HealthKit + Widgets

HealthKitBridge, écran historique + Charts, 3 widgets WidgetKit, audit accessibilité.

### Sprint 5 — Polish + CI/CD + App Store

Xcode Cloud, TestFlight, Fastlane, Privacy Manifest, localisation FR/EN.

---

## 🔄 BOUCLES DE QUALITÉ

```
Agent Spécialisé → Code
    ↓
Agent-Reviewer → Review (checklist)
    ↓ (si issues)
Agent Spécialisé → Fix
    ↓ (si OK)
Agent-Security → Audit
    ↓
Agent-Tests → Coverage
    ↓
Orchestrateur → Merge
```

À chaque PR : SwiftLint `--strict` = 0 warning, tous les tests verts, DocC build OK.

---

## 📌 RÈGLES GLOBALES

1. **Analysis First** — documenter les décisions dans les commits et la DocC.
2. **Swift 6.2 strict** — zéro data race. Tout type traversant les boundaries = `Sendable`.
3. **Tests first pour domaine** — TDD pour Agent-Domain.
4. **DocC en même temps que le code**, pas après.
5. **Logs structurés** — `os.Logger(subsystem: "com.samuel.walkforge", category: …)`, jamais `print()` en prod.
6. **Feature flags** — abstractions pour watchOS/macOS dès le Sprint 1.
7. **Matériel réel en Sprint 1** — mode mock complet pour simulateur + tests hardware dès disponibilité du PORTENTUM 8 Pro.

---

*Version 1.1 — Consolidé et corrigé (opcodes FTMS, nom d'app validé : WalkForge).*
