// WalkForge — DomainKit
// Agent-Domain: estimation MET-based des calories dépensées.
//
// Formule : Calories(kcal) = MET × poids(kg) × durée(h)
//
// Valeurs MET issues du Compendium of Physical Activities (Ainsworth et al.)
// pour la marche et la marche rapide. Approximations pour notre plage 1–6 km/h :
//
// |  Vitesse (km/h) | MET  |
// | ---------------- | ---- |
// |  < 2.0           | 2.0  |
// |  2.0 – 3.0       | 2.5  |
// |  3.0 – 4.0       | 3.3  |
// |  4.0 – 5.0       | 4.3  |
// |  5.0 – 6.0       | 5.8  |
// |  ≥ 6.0           | 7.0  |
//
// Inclinaison : facteur multiplicatif +5 % par point de % (approximation).

import Foundation

/// Use case pur de calcul de calories.
///
/// Aucune dépendance (pas de BLE, pas de persistance). Testable en isolation
/// complète.
public struct CalculateCaloriesUseCase: Sendable {
    public init() {}

    /// Estime les calories dépensées pour une période à vitesse et inclinaison constantes.
    public func execute(
        weightKg: Double,
        speedKmh: Double,
        durationSeconds: Int,
        inclinePercent: Double = 0,
    ) -> Double {
        guard durationSeconds > 0, weightKg > 0, speedKmh > 0 else { return 0 }
        let met = Self.metValue(for: speedKmh, inclinePercent: inclinePercent)
        let hours = Double(durationSeconds) / 3600.0
        return met * weightKg * hours
    }

    /// MET correspondant à une vitesse + inclinaison données.
    public static func metValue(for speedKmh: Double, inclinePercent: Double) -> Double {
        let baseMET = switch speedKmh {
        case ..<2.0: 2.0
        case 2.0 ..< 3.0: 2.5
        case 3.0 ..< 4.0: 3.3
        case 4.0 ..< 5.0: 4.3
        case 5.0 ..< 6.0: 5.8
        default: 7.0
        }
        let inclineFactor = 1.0 + max(0, inclinePercent) * 0.05
        return baseMET * inclineFactor
    }
}
