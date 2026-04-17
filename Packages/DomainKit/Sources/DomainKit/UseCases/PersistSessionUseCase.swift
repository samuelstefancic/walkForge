// WalkForge — DomainKit
// Agent-Domain: persiste une session terminée via le WorkoutSessionRepository.

import Foundation

/// Use case de persistance d'une session terminée.
///
/// Orchestre :
/// 1. Construit un `WorkoutSessionDTO` à partir du `SessionSummary` et
///    des dates de début/fin.
/// 2. Appelle `WorkoutSessionRepository.save`.
///
/// Séparé de `StopSessionUseCase` pour garder la responsabilité "arrêt
/// BLE" distincte de la responsabilité "persistance" (testables
/// indépendamment, substituables en mode demo sans persistance).
public struct PersistSessionUseCase: Sendable {
    private let repository: any WorkoutSessionRepository

    public init(repository: any WorkoutSessionRepository) {
        self.repository = repository
    }

    /// Persiste une session terminée.
    ///
    /// - Returns: le DTO persisté (avec `id` généré).
    @discardableResult
    public func execute(
        summary: SessionSummary,
        startDate: Date,
        endDate: Date = Date(),
        inclineLevel: Int,
    ) async throws -> WorkoutSessionDTO {
        let dto = WorkoutSessionDTO(
            startDate: startDate,
            endDate: endDate,
            durationSeconds: summary.durationSeconds,
            distanceKm: summary.distanceKm,
            estimatedCalories: summary.estimatedCalories,
            averageSpeedKmh: summary.averageSpeedKmh,
            maxSpeedKmh: summary.maxSpeedKmh,
            inclineLevel: inclineLevel,
        )
        try await repository.save(dto)
        return dto
    }
}
