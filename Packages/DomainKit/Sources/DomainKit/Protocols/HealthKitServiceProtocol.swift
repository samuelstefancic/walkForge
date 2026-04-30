// WalkForge — DomainKit
// Agent-Domain: contrat HealthKit consommé par les ViewModels.
// Implémenté par HealthKitBridge (Sprint 4).

import Foundation

/// État de la permission HealthKit pour un type donné.
public enum HealthKitAuthorization: Sendable, Equatable, Hashable {
    case notDetermined
    case sharingDenied
    case sharingAuthorized
}

/// Snapshot du profil utilisateur lu depuis HealthKit (pré-remplissage UI).
public struct HealthKitProfileSnapshot: Sendable, Equatable, Hashable {
    public let weightKg: Double?
    public let heightCm: Double?
    public let ageYears: Int?
    public let biologicalSex: HealthKitBiologicalSex?

    public init(
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        ageYears: Int? = nil,
        biologicalSex: HealthKitBiologicalSex? = nil,
    ) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.ageYears = ageYears
        self.biologicalSex = biologicalSex
    }
}

public enum HealthKitBiologicalSex: Sendable, Equatable, Hashable {
    case female
    case male
    case other
    case notSet
}

/// Contrat de la couche HealthKit.
///
/// Implémenté par `HealthKitBridge.HealthKitService` (production) et un mock
/// `InMemoryHealthKitService` pour tests/previews.
public protocol HealthKitServiceProtocol: Sendable {
    /// Vérifie si HealthKit est dispo sur cet appareil (iPad ne l'a pas).
    var isAvailable: Bool { get async }

    /// État courant de l'autorisation pour les types WalkForge (granulaire).
    func authorizationStatus() async -> HealthKitAuthorization

    /// Demande la permission pour les types WalkForge :
    /// - Read: `weight`, `height`, `dateOfBirth`, `biologicalSex`, `heartRate`
    /// - Write: `workout`, `distanceWalkingRunning`, `activeEnergyBurned`
    func requestAuthorization() async throws -> HealthKitAuthorization

    /// Lit le profil utilisateur depuis HealthKit (snapshot, peut être partiel).
    func readProfile() async throws -> HealthKitProfileSnapshot

    /// Exporte une session vers HealthKit comme `HKWorkout`.
    /// Renvoie `true` si l'export a réussi (autorisations + sauvegarde OK).
    @discardableResult
    func exportWorkout(_ session: WorkoutSessionDTO) async throws -> Bool
}
