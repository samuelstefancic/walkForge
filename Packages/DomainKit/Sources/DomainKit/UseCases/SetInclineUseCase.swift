// WalkForge — DomainKit
// Agent-Domain: change le niveau d'inclinaison du tapis.

import Foundation

/// Use case de changement d'inclinaison.
///
/// Prend en entrée un `InclineLevel` discret (flat/low/medium/high) et envoie
/// le pourcentage correspondant via `Set Target Inclination` (`0x03`).
public struct SetInclineUseCase: Sendable {
    private let bleService: any BLETreadmillServiceProtocol

    public init(bleService: any BLETreadmillServiceProtocol) {
        self.bleService = bleService
    }

    /// Change l'inclinaison cible.
    public func execute(level: InclineLevel) async throws(TreadmillError) {
        try await bleService.setTargetInclination(percent: level.percentValue)
    }
}
