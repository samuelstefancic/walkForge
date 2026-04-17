// WalkForge — DomainKit
// Agent-Domain: contrat BLE consommé par la couche Presentation, implémenté
// par BLECore (vraie implémentation CoreBluetooth + Mock pour tests/simulateur).

import Foundation

/// Abstraction du service BLE de contrôle du tapis.
///
/// Implémenté par :
/// - `BLECore.BLEManager` (CoreBluetooth, production)
/// - `BLECore.MockBLEManager` (simulateur, tests unitaires et mode demo)
///
/// La couche Presentation (ViewModels SwiftUI) dépend uniquement de ce protocol.
/// Elle peut ainsi être testée sans simulateur iOS ni hardware BLE.
public protocol BLETreadmillServiceProtocol: Sendable {
    // MARK: - Streams

    /// Émet à chaque transition d'état de la connexion.
    ///
    /// - Note : le stream n'émet pas automatiquement l'état initial. Les
    ///   consommateurs doivent lire `currentConnectionState` séparément si besoin.
    var connectionStateStream: AsyncStream<TreadmillConnectionState> { get }

    /// Émet à chaque notification `Treadmill Data` (`0x2ACD`) du tapis.
    var treadmillDataStream: AsyncStream<TreadmillData> { get }

    /// Émet chaque appareil découvert pendant le scan (dédupliqué par ID).
    var discoveredDevicesStream: AsyncStream<DiscoveredDevice> { get }

    /// État actuel de la connexion (snapshot synchrone).
    var currentConnectionState: TreadmillConnectionState { get async }

    // MARK: - Lifecycle

    /// Démarre le scan d'appareils annonçant le service FTMS (`0x1826`).
    func startScanning() async throws(TreadmillError)

    /// Arrête le scan en cours (no-op si aucun scan actif).
    func stopScanning() async

    /// Établit la connexion à un appareil précédemment découvert.
    func connect(to deviceID: String) async throws(TreadmillError)

    /// Déconnecte proprement l'appareil courant (no-op si non connecté).
    func disconnect() async

    // MARK: - FTMS Control

    /// Envoie `Request Control` (`0x00`). À faire avant toute commande.
    func requestControl() async throws(TreadmillError)

    /// Envoie `Start or Resume` (`0x07`).
    func start() async throws(TreadmillError)

    /// Envoie `Stop or Pause` (`0x08`) avec operand `0x01` (Stop).
    func stop() async throws(TreadmillError)

    /// Envoie `Stop or Pause` (`0x08`) avec operand `0x02` (Pause).
    func pause() async throws(TreadmillError)

    /// Envoie `Reset` (`0x01`).
    func reset() async throws(TreadmillError)

    /// Envoie `Set Target Speed` (`0x02`). La vitesse est en km/h.
    func setTargetSpeed(kmh: Double) async throws(TreadmillError)

    /// Envoie `Set Target Inclination` (`0x03`). L'inclinaison est en %.
    func setTargetInclination(percent: Double) async throws(TreadmillError)
}
