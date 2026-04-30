// WalkForge — HealthKitBridgeTests
// Agent-Tests: vérifie les mocks (le vrai HealthKitService nécessite un appareil
// physique avec entitlement HK, donc testé manuellement plus tard).

import DomainKit
import Foundation
@testable import HealthKitBridge
import Testing

@Suite("InMemoryHealthKitService")
struct InMemoryHealthKitServiceTests {
    @Test("Snapshot par défaut renvoyé tel quel")
    func defaultSnapshot() async throws {
        let service = InMemoryHealthKitService()
        let snapshot = try await service.readProfile()
        #expect(snapshot.weightKg == 75)
        #expect(snapshot.heightCm == 175)
        #expect(snapshot.ageYears == 30)
    }

    @Test("requestAuthorization → sharingAuthorized")
    func authorize() async throws {
        let service = InMemoryHealthKitService(authorization: .notDetermined)
        let result = try await service.requestAuthorization()
        #expect(result == .sharingAuthorized)
    }

    @Test("exportWorkout enregistre l'ID de session")
    func exportRecordsID() async throws {
        let service = InMemoryHealthKitService()
        let session = WorkoutSessionDTO(
            startDate: Date(),
            durationSeconds: 600,
            distanceKm: 1.0,
            estimatedCalories: 50,
            averageSpeedKmh: 3.0,
            maxSpeedKmh: 4.0,
            inclineLevel: 1,
        )
        let success = try await service.exportWorkout(session)
        #expect(success)
        let lastID = await service.lastExportedSessionID
        #expect(lastID == session.id)
    }
}
