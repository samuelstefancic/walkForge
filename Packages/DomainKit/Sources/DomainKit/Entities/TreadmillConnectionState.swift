// WalkForge — DomainKit
// Agent-Domain: machine à états de la connexion BLE au tapis.

import Foundation

/// État de la connexion Bluetooth au tapis.
///
/// Machine à états consommée par la couche Presentation pour afficher le statut
/// de connexion et réagir aux transitions (animations, alertes utilisateur).
public enum TreadmillConnectionState: Sendable, Equatable, Hashable {
    /// Bluetooth indisponible sur l'appareil (iPad sans BT, etc.).
    case unsupported

    /// Bluetooth désactivé par l'utilisateur : demander à l'activer.
    case poweredOff

    /// Permission Bluetooth refusée ou non déterminée.
    case unauthorized

    /// Bluetooth activé, prêt à scanner.
    case idle

    /// Scan en cours.
    case scanning

    /// Connexion en cours à un appareil identifié.
    case connecting(deviceID: String)

    /// Connecté, services et caractéristiques FTMS découverts, prêt à piloter.
    case connected(deviceID: String)

    /// Déconnexion volontaire en cours.
    case disconnecting

    /// Déconnecté (après une connexion ou après un échec).
    case disconnected

    /// Échec : impossible de se connecter ou perte de connexion imprévue.
    case failed(reason: String)
}
