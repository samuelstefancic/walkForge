// WalkForge — DomainKit
// Agent-Domain: contrat repository de persistance des sessions d'entraînement.
// Sera implémenté par DataKit au Sprint 3 (SwiftData).

import Foundation

/// Repository de persistance des sessions d'entraînement.
///
/// Implémenté par `DataKit.WorkoutSessionSwiftDataRepository` (Sprint 3).
public protocol WorkoutSessionRepository: Sendable {
    /// Sauvegarde une nouvelle session ou met à jour une session existante (par `id`).
    func save(_ session: WorkoutSessionDTO) async throws

    /// Liste toutes les sessions triées par `startDate` décroissant.
    func listAll() async throws -> [WorkoutSessionDTO]

    /// Liste les sessions démarrées entre `from` et `to` (inclus).
    func list(from: Date, to: Date) async throws -> [WorkoutSessionDTO]

    /// Récupère une session par son identifiant.
    func find(id: UUID) async throws -> WorkoutSessionDTO?

    /// Supprime une session par son identifiant.
    func delete(id: UUID) async throws

    /// Nombre de jours consécutifs avec au moins une session (streak actuel).
    func currentStreakDays(now: Date) async throws -> Int
}

/// Data transfer object utilisé par le repository.
///
/// Séparé des `@Model` SwiftData pour éviter de coupler DomainKit à SwiftData.
public struct WorkoutSessionDTO: Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date?
    public let durationSeconds: Int
    public let distanceKm: Double
    public let estimatedCalories: Double
    public let averageSpeedKmh: Double
    public let maxSpeedKmh: Double
    public let inclineLevel: Int
    public let isExportedToHealthKit: Bool

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        durationSeconds: Int,
        distanceKm: Double,
        estimatedCalories: Double,
        averageSpeedKmh: Double,
        maxSpeedKmh: Double,
        inclineLevel: Int,
        isExportedToHealthKit: Bool = false,
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.durationSeconds = durationSeconds
        self.distanceKm = distanceKm
        self.estimatedCalories = estimatedCalories
        self.averageSpeedKmh = averageSpeedKmh
        self.maxSpeedKmh = maxSpeedKmh
        self.inclineLevel = inclineLevel
        self.isExportedToHealthKit = isExportedToHealthKit
    }
}
