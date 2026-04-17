// WalkForge — DomainKit
// Agent-Domain: orchestre le démarrage d'une session (request control + start FTMS).

import Foundation

/// Use case de démarrage de session.
///
/// Flux :
/// 1. Demande le contrôle FTMS au tapis (`0x00`)
/// 2. Envoie `Start or Resume` (`0x07`)
///
/// À terme (Sprint 3+) : démarre aussi `HKWorkoutSession` si Apple Watch connectée,
/// enregistre un timestamp pour calcul durée côté ViewModel.
public struct StartSessionUseCase: Sendable {
    private let bleService: any BLETreadmillServiceProtocol

    public init(bleService: any BLETreadmillServiceProtocol) {
        self.bleService = bleService
    }

    /// Démarre la session. Peut échouer si le tapis n'est pas connecté ou
    /// refuse la prise de contrôle.
    public func execute() async throws(TreadmillError) {
        try await bleService.requestControl()
        try await bleService.start()
    }
}
