// WalkForge — DomainKit
// Agent-Domain: contrat repository du profil utilisateur.
// Sera implémenté par DataKit au Sprint 3 (SwiftData).

import Foundation

/// Repository du profil utilisateur (données de santé personnelles et objectifs).
///
/// Implémenté par `DataKit.UserProfileSwiftDataRepository` (Sprint 3).
public protocol UserProfileRepository: Sendable {
    /// Charge le profil, ou `nil` si aucun profil n'a encore été créé.
    func load() async throws -> UserProfileDTO?

    /// Sauvegarde (création ou mise à jour) du profil.
    func save(_ profile: UserProfileDTO) async throws
}

/// DTO du profil utilisateur.
public struct UserProfileDTO: Sendable, Equatable, Hashable {
    public var weightKg: Double
    public var heightCm: Double
    public var ageYears: Int
    public var preferredSpeedKmh: Double
    public var dailyStepGoal: Int
    public var dailyDistanceGoalKm: Double
    public var lastLubricationDate: Date?
    public var totalSessionCount: Int
    public var nextMaintenanceAlertDate: Date?

    public init(
        weightKg: Double,
        heightCm: Double,
        ageYears: Int,
        preferredSpeedKmh: Double = 3.0,
        dailyStepGoal: Int = 8000,
        dailyDistanceGoalKm: Double = 5.0,
        lastLubricationDate: Date? = nil,
        totalSessionCount: Int = 0,
        nextMaintenanceAlertDate: Date? = nil,
    ) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.ageYears = ageYears
        self.preferredSpeedKmh = preferredSpeedKmh
        self.dailyStepGoal = dailyStepGoal
        self.dailyDistanceGoalKm = dailyDistanceGoalKm
        self.lastLubricationDate = lastLubricationDate
        self.totalSessionCount = totalSessionCount
        self.nextMaintenanceAlertDate = nextMaintenanceAlertDate
    }
}
