# Architecture — WalkForge

## Vue d'ensemble

WalkForge suit une **Clean Architecture** à 3 couches avec modules **Swift Package Manager** indépendants.

```
┌──────────────────────────────────────────────┐
│           PRESENTATION LAYER                  │   ← SwiftUI, @Observable, Widgets
│   ─────────────────────────────              │
│   App/ · DesignSystem/ · WidgetExtension/     │
├──────────────────────────────────────────────┤
│             DOMAIN LAYER                      │   ← Pure Swift, no framework deps
│   ─────────────────────                      │
│   DomainKit/ (entities · protocols · errors)  │
├──────────────────────────────────────────────┤
│              DATA LAYER                       │   ← CoreBluetooth, SwiftData, HealthKit
│   ─────────────                              │
│   BLECore/ · DataKit/ · HealthKitBridge/      │
│   NotificationKit/                            │
└──────────────────────────────────────────────┘
```

### Règle de dépendance

```
Presentation  →  Domain  ←  Data
```

**DomainKit** ne dépend d'aucun framework Apple (pure Swift). Les couches externes implémentent les protocols définis dans DomainKit. C'est le principe d'**inversion de dépendance**.

---

## Modules SPM

### DomainKit

**Dépendances** : aucune (pure Swift).

**Expose** :
- Entités : `TreadmillData`, `DiscoveredDevice`, `TreadmillConnectionState`, `SpeedRange`, `InclineLevel`
- Protocols : `BLETreadmillServiceProtocol`, `WorkoutSessionRepository`, `UserProfileRepository`, `SessionProgramRepository`
- Erreurs : `TreadmillError` (typé)

**Testable** sans simulateur iOS (plateforme macOS suffit).

### BLECore

**Dépendances** : `DomainKit` (locale, `path: "../DomainKit"`), `CoreBluetooth` (Apple).

**Expose** :
- `FTMSTreadmillDataParser` — parser binaire des trames `Treadmill Data` (`0x2ACD`)
- `FTMSControlCommand` — encodage des commandes Control Point (`0x2AD9`)
- `BLEManager` — implémentation CoreBluetooth de `BLETreadmillServiceProtocol`
- `MockBLEManager` — simulateur complet pour tests unitaires et mode simulateur

**Testable** sur macOS (CoreBluetooth présent). Tests unitaires = parsing + mock. Tests hardware = sur iPhone avec PORTENTUM 8 Pro.

---

## Concurrence — Swift 6.2 strict

- Tous les types traversant des boundaries actor = `Sendable`
- `TreadmillData`, `DiscoveredDevice`, `TreadmillConnectionState` = structs/enums `Sendable`
- `BLEManager` = `@unchecked Sendable` car il wrappe `CBCentralManager` (API Objective-C pré-concurrence). Tout l'état mutable est protégé par un `DispatchQueue` sériel unique (`com.samuel.walkforge.ble.central`).
- `MockBLEManager` = `actor` (état pleinement isolé).
- Streams réactifs : `AsyncStream<TreadmillData>` + `AsyncStream<TreadmillConnectionState>`.

---

## Contrats inter-couches

### `BLETreadmillServiceProtocol`

Abstraction BLE exposée par `DomainKit`, implémentée par `BLECore`. Permet à la couche Presentation (Sprint 2) d'être testable sans dépendance à CoreBluetooth.

```swift
public protocol BLETreadmillServiceProtocol: Sendable {
    var connectionStateStream: AsyncStream<TreadmillConnectionState> { get }
    var treadmillDataStream: AsyncStream<TreadmillData> { get }
    var discoveredDevicesStream: AsyncStream<DiscoveredDevice> { get }

    func startScanning() async throws(TreadmillError)
    func stopScanning() async
    func connect(to deviceID: String) async throws(TreadmillError)
    func disconnect() async

    func requestControl() async throws(TreadmillError)
    func start() async throws(TreadmillError)
    func stop() async throws(TreadmillError)
    func pause() async throws(TreadmillError)
    func reset() async throws(TreadmillError)
    func setTargetSpeed(kmh: Double) async throws(TreadmillError)
    func setTargetInclination(percent: Double) async throws(TreadmillError)
}
```

---

## Décisions architecturales (ADR concis)

### ADR-001 — SPM multi-packages vs monolithe

**Choix** : SPM multi-packages (`Packages/{DomainKit,BLECore,…}`).

**Raison** :
- Compilation incrémentale plus rapide
- Tests unitaires isolés par module
- Swap plus facile pour tests UI (injecter `MockBLEManager`)
- Prépare extensions watchOS / macOS Catalyst (Sprint 5+)

**Tradeoff** : plus de boilerplate (`Package.swift` par module). Acceptable vu l'ambition du projet.

### ADR-002 — Typed throws (`throws(TreadmillError)`)

**Choix** : typed throws pour toutes les API publiques domaine.

**Raison** :
- Swift 6.2 supporte la feature nativement
- Compile-time enforcement des cas d'erreur à gérer côté UI
- Alignement avec la philosophie CQRS/Event Sourcing de l'utilisateur (erreurs = événements typés)

### ADR-003 — MockBLEManager = `actor`, BLEManager = `@unchecked Sendable`

**Choix** : isolation différente selon l'implémentation.

**Raison** :
- `MockBLEManager` a un état full-Swift → `actor` donne une isolation propre gratuite
- `BLEManager` wrappe `CBCentralManager` qui impose des callbacks synchrones sur sa propre `DispatchQueue` → pattern `@unchecked Sendable` + queue sérielle est le pattern canonique pour wrapper les APIs Objective-C delegate-based

### ADR-004 — FTMS Spec officielle vs spec constructeur

**Choix** : implémenter la spec Bluetooth SIG FTMS officielle, pas les variations PORTENTUM supposées.

**Raison** :
- Portabilité : toute machine FTMS-compliant fonctionnera (multi-marque à long terme)
- Robustesse : tests basés sur trames conformes spec = moins de surprises

Les variations constructeur (si elles existent) seront gérées en Sprint 1.5 après tests hardware réels.

---

## Roadmap modules (par sprint)

| Module                   | Sprint | Statut         |
| ------------------------ | ------ | -------------- |
| `DomainKit`              | 1      | ✅ Livré       |
| `BLECore`                | 1      | ✅ Livré       |
| `DesignSystem`           | 2      | ⏳ Prévu       |
| `DataKit`                | 3      | ⏳ Prévu       |
| `NotificationKit`        | 3      | ⏳ Prévu       |
| `HealthKitBridge`        | 4      | ⏳ Prévu       |
| `WidgetExtension`        | 4      | ⏳ Prévu       |
| `App/` (Xcode target)    | 2      | ⏳ Prévu       |
| `WatchApp/` (scaffold)   | 5      | ⏳ Prévu       |
