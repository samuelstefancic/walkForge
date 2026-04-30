// WalkForge — HealthKitBridge
// Agent-Infra: mock pour previews et tests UI sans entitlement HealthKit.

import DomainKit
import Foundation

/// Mock du `HealthKitServiceProtocol` qui ne touche pas HealthKit.
///
/// Utile :
/// - en previews SwiftUI (HealthKit n'est pas dispo dans les previews)
/// - en tests UI / unit tests
/// - en mode demo sans Apple Developer Program
public actor InMemoryHealthKitService: HealthKitServiceProtocol {
    public private(set) var lastExportedSessionID: UUID?
    public private(set) var snapshot: HealthKitProfileSnapshot
    public private(set) var authorization: HealthKitAuthorization

    public init(
        snapshot: HealthKitProfileSnapshot = HealthKitProfileSnapshot(
            weightKg: 75,
            heightCm: 175,
            ageYears: 30,
            biologicalSex: .other,
        ),
        authorization: HealthKitAuthorization = .sharingAuthorized,
    ) {
        self.snapshot = snapshot
        self.authorization = authorization
    }

    public nonisolated var isAvailable: Bool {
        get async { true }
    }

    public func authorizationStatus() async -> HealthKitAuthorization {
        authorization
    }

    public func requestAuthorization() async throws -> HealthKitAuthorization {
        authorization = .sharingAuthorized
        return authorization
    }

    public func readProfile() async throws -> HealthKitProfileSnapshot {
        snapshot
    }

    @discardableResult
    public func exportWorkout(_ session: WorkoutSessionDTO) async throws -> Bool {
        lastExportedSessionID = session.id
        return true
    }
}
