// WalkForge — DomainKit
// Agent-Domain: erreurs typées remontées par la couche BLE et les use cases.

import Foundation

/// Erreur typée remontée par la couche BLE ou par un use case domaine.
///
/// Conçue pour être consommée par typed throws Swift 6 (`throws(TreadmillError)`).
/// La couche Presentation peut faire un `switch` exhaustif pour afficher le bon
/// message utilisateur ou déclencher une action (ex: demander d'activer le BT).
public enum TreadmillError: Error, Sendable, Equatable, Hashable {
    /// L'appareil ne supporte pas Bluetooth Low Energy.
    case bluetoothUnavailable

    /// L'utilisateur n'a pas accordé la permission Bluetooth.
    case bluetoothUnauthorized

    /// Bluetooth est désactivé au niveau système.
    case bluetoothPoweredOff

    /// Aucun appareil trouvé pendant le scan (timeout).
    case deviceNotFound

    /// La connexion a échoué (raison technique de CoreBluetooth).
    case connectionFailed(reason: String)

    /// Connexion perdue de façon imprévue.
    case disconnected

    /// Pas de contrôle FTMS accordé par le tapis (commande `0x00` non réussie).
    case controlNotGranted

    /// Vitesse hors plage ou non alignée sur le pas.
    case invalidSpeed(requested: Double, min: Double, max: Double)

    /// Inclinaison hors plage.
    case invalidInclination(requested: Double)

    /// Erreur de parsing d'une trame FTMS.
    case ftmsParseError(reason: String)

    /// Le tapis a rejeté une commande FTMS (result code non-success).
    case ftmsOperationFailed(opcode: UInt8, resultCode: UInt8)

    /// Opcode FTMS non supporté par le tapis.
    case notSupported(opcode: UInt8)

    /// Timeout d'une opération (connexion, commande).
    case timeout

    /// Commande envoyée alors qu'aucun tapis n'est connecté.
    case notConnected
}

extension TreadmillError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bluetoothUnavailable:
            "Bluetooth Low Energy non disponible sur cet appareil."
        case .bluetoothUnauthorized:
            "Permission Bluetooth non accordée."
        case .bluetoothPoweredOff:
            "Bluetooth désactivé. Activez-le dans les réglages."
        case .deviceNotFound:
            "Aucun tapis FTMS détecté à proximité."
        case let .connectionFailed(reason):
            "Connexion échouée : \(reason)"
        case .disconnected:
            "Connexion perdue."
        case .controlNotGranted:
            "Le tapis n'a pas accepté la prise de contrôle."
        case let .invalidSpeed(requested, min, max):
            "Vitesse \(requested) km/h invalide (plage \(min)–\(max))."
        case let .invalidInclination(requested):
            "Inclinaison \(requested) % invalide."
        case let .ftmsParseError(reason):
            "Erreur de décodage FTMS : \(reason)"
        case let .ftmsOperationFailed(opcode, resultCode):
            "Commande FTMS \(String(format: "0x%02X", opcode)) rejetée "
                + "(code \(String(format: "0x%02X", resultCode)))."
        case let .notSupported(opcode):
            "Opération FTMS \(String(format: "0x%02X", opcode)) non supportée."
        case .timeout:
            "Opération expirée."
        case .notConnected:
            "Aucun tapis connecté."
        }
    }
}
