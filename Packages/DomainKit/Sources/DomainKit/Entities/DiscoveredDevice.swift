// WalkForge — DomainKit
// Agent-Domain: appareil BLE découvert lors du scan (abstraction de CBPeripheral).

import Foundation

/// Appareil BLE découvert pendant un scan, avant connexion.
///
/// Enveloppe un identifiant unique (dérivé de `CBPeripheral.identifier`) pour
/// permettre à la couche Presentation de lister et sélectionner les appareils
/// sans importer `CoreBluetooth`.
public struct DiscoveredDevice: Sendable, Equatable, Hashable, Identifiable {
    /// Identifiant stable de l'appareil (UUID stringifié).
    public let id: String

    /// Nom annoncé par l'appareil. `nil` si l'appareil ne diffuse pas de nom.
    public let name: String?

    /// Received Signal Strength Indication (dBm). Plus proche de 0 = meilleur signal.
    public let rssi: Int

    /// `true` si l'appareil annonce le service FTMS (UUID `0x1826`).
    public let advertisesFTMS: Bool

    public init(id: String, name: String?, rssi: Int, advertisesFTMS: Bool) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.advertisesFTMS = advertisesFTMS
    }

    /// Nom affichable : le nom annoncé, ou un fallback sur l'ID tronqué.
    public var displayName: String {
        if let name, !name.isEmpty {
            return name
        }
        return "Appareil " + String(id.prefix(8))
    }
}
