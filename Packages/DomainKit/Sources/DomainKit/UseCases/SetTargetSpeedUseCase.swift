// WalkForge — DomainKit
// Agent-Domain: valide la vitesse demandée puis envoie la commande FTMS.

import Foundation

/// Use case de changement de vitesse cible.
///
/// Valide la vitesse contre la plage du modèle de tapis (ex. PORTENTUM 8 Pro :
/// 1–6 km/h par pas de 0.5) avant d'envoyer la commande `Set Target Speed`
/// (`0x02`).
public struct SetTargetSpeedUseCase: Sendable {
    private let bleService: any BLETreadmillServiceProtocol
    private let range: SpeedRange

    public init(
        bleService: any BLETreadmillServiceProtocol,
        range: SpeedRange = .portentum8Pro,
    ) {
        self.bleService = bleService
        self.range = range
    }

    /// Change la vitesse cible. La valeur est d'abord arrondie (`snap`) à un
    /// pas valide, puis validée, puis envoyée au tapis.
    ///
    /// - Returns: la vitesse effectivement envoyée au tapis (post-snap).
    @discardableResult
    public func execute(kmh: Double) async throws(TreadmillError) -> Double {
        let snapped = range.snap(kmh)
        guard range.isValid(snapped) else {
            throw .invalidSpeed(requested: kmh, min: range.minKmh, max: range.maxKmh)
        }
        try await bleService.setTargetSpeed(kmh: snapped)
        return snapped
    }
}
