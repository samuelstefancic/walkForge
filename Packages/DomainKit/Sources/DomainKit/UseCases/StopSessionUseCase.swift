// WalkForge — DomainKit
// Agent-Domain: arrête la session courante et renvoie un résumé statistique.

import Foundation

/// Résumé d'une session arrêtée.
public struct SessionSummary: Sendable, Equatable, Hashable {
    public let distanceKm: Double
    public let durationSeconds: Int
    public let averageSpeedKmh: Double
    public let maxSpeedKmh: Double
    public let estimatedCalories: Double

    public init(
        distanceKm: Double,
        durationSeconds: Int,
        averageSpeedKmh: Double,
        maxSpeedKmh: Double,
        estimatedCalories: Double,
    ) {
        self.distanceKm = distanceKm
        self.durationSeconds = durationSeconds
        self.averageSpeedKmh = averageSpeedKmh
        self.maxSpeedKmh = maxSpeedKmh
        self.estimatedCalories = estimatedCalories
    }
}

/// Use case d'arrêt de session.
///
/// Flux :
/// 1. Envoie `Stop or Pause` (`0x08` + operand Stop)
/// 2. Calcule le résumé statistique à partir du dernier snapshot et de l'historique
/// 3. Retourne le `SessionSummary`
public struct StopSessionUseCase: Sendable {
    private let bleService: any BLETreadmillServiceProtocol

    public init(bleService: any BLETreadmillServiceProtocol) {
        self.bleService = bleService
    }

    /// Arrête la session. Prend en entrée le dernier snapshot observé et
    /// l'historique pour calculer les stats. Délègue la persistance au caller
    /// (ViewModel → DataKit au Sprint 3).
    public func execute(
        lastSnapshot: TreadmillData,
        history: [TreadmillData],
    ) async throws(TreadmillError) -> SessionSummary {
        try await bleService.stop()

        let averageSpeed = computeAverageSpeed(history: history, lastSnapshot: lastSnapshot)
        let maxSpeed = history.map(\.speedKmh).max() ?? lastSnapshot.speedKmh
        let calories = lastSnapshot.totalEnergyKcal ?? 0

        return SessionSummary(
            distanceKm: lastSnapshot.distanceKm,
            durationSeconds: lastSnapshot.elapsedTimeSeconds,
            averageSpeedKmh: averageSpeed,
            maxSpeedKmh: maxSpeed,
            estimatedCalories: calories,
        )
    }

    /// Moyenne arithmétique simple sur les snapshots où la vitesse > 0.
    /// Une moyenne pondérée par la durée serait plus précise mais suffit au Sprint 2.
    private func computeAverageSpeed(
        history: [TreadmillData],
        lastSnapshot: TreadmillData,
    ) -> Double {
        let allSnapshots = history + [lastSnapshot]
        let nonZero = allSnapshots.filter { $0.speedKmh > 0 }
        guard !nonZero.isEmpty else { return 0 }
        let sum = nonZero.reduce(0.0) { $0 + $1.speedKmh }
        return sum / Double(nonZero.count)
    }
}
