// WalkForge — DomainKitTests
// Agent-Tests: PersistSessionUseCase construit le DTO et délègue au repository.

@testable import DomainKit
import Foundation
import Testing

@Suite("PersistSessionUseCase")
struct PersistSessionUseCaseTests {
    @Test("Construit un DTO cohérent avec le SessionSummary")
    func buildsDTOFromSummary() async throws {
        let repository = InMemoryWorkoutSessionRepository()
        let useCase = PersistSessionUseCase(repository: repository)

        let summary = SessionSummary(
            distanceKm: 1.23,
            durationSeconds: 450,
            averageSpeedKmh: 3.5,
            maxSpeedKmh: 4.0,
            estimatedCalories: 38.5,
        )
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_000_450)

        let dto = try await useCase.execute(
            summary: summary,
            startDate: start,
            endDate: end,
            inclineLevel: 2,
        )

        #expect(dto.distanceKm == 1.23)
        #expect(dto.durationSeconds == 450)
        #expect(dto.averageSpeedKmh == 3.5)
        #expect(dto.maxSpeedKmh == 4.0)
        #expect(dto.estimatedCalories == 38.5)
        #expect(dto.inclineLevel == 2)
        #expect(dto.startDate == start)
        #expect(dto.endDate == end)

        let stored = try await repository.find(id: dto.id)
        #expect(stored == dto)
    }

    @Test("Remonte l'erreur du repository si save échoue")
    func propagatesRepositoryError() async throws {
        let repository = InMemoryWorkoutSessionRepository()
        await repository.setError()
        let useCase = PersistSessionUseCase(repository: repository)

        let summary = SessionSummary(
            distanceKm: 0,
            durationSeconds: 0,
            averageSpeedKmh: 0,
            maxSpeedKmh: 0,
            estimatedCalories: 0,
        )

        await #expect(throws: TestPersistenceError.self) {
            _ = try await useCase.execute(
                summary: summary,
                startDate: Date(),
                endDate: Date(),
                inclineLevel: 0,
            )
        }
    }
}

/// Erreur symbolique utilisée par les tests de repository.
enum TestPersistenceError: Error { case simulated }

extension InMemoryWorkoutSessionRepository {
    func setError() {
        errorToThrow = TestPersistenceError.simulated
    }
}
