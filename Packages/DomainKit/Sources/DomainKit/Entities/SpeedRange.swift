// WalkForge — DomainKit
// Agent-Domain: plage de vitesse valide (spécifique au modèle de tapis).

import Foundation

/// Plage de vitesse autorisée par un modèle de tapis.
///
/// Chaque modèle a une plage différente (le PORTENTUM 8 Pro : 1–6 km/h par pas de 0.5).
/// Le `SetTargetSpeedUseCase` (Sprint 2) valide que la vitesse demandée respecte
/// cette plage avant d'envoyer la commande FTMS.
public struct SpeedRange: Sendable, Equatable, Hashable {
    public let minKmh: Double
    public let maxKmh: Double
    public let stepKmh: Double

    public init(minKmh: Double, maxKmh: Double, stepKmh: Double) {
        self.minKmh = minKmh
        self.maxKmh = maxKmh
        self.stepKmh = stepKmh
    }

    /// Plage par défaut du PORTENTUM Treadmill 8 Pro.
    public static let portentum8Pro: SpeedRange = .init(
        minKmh: 1.0,
        maxKmh: 6.0,
        stepKmh: 0.5,
    )

    /// Renvoie `true` si la vitesse est dans la plage ET alignée sur un pas.
    public func isValid(_ kmh: Double) -> Bool {
        guard kmh >= minKmh, kmh <= maxKmh else { return false }
        let steps = (kmh - minKmh) / stepKmh
        return abs(steps.rounded() - steps) < 0.001
    }

    /// Arrondit la vitesse demandée au pas le plus proche, clampé dans la plage.
    public func snap(_ kmh: Double) -> Double {
        let clamped = min(max(kmh, minKmh), maxKmh)
        let steps = ((clamped - minKmh) / stepKmh).rounded()
        return minKmh + steps * stepKmh
    }
}
