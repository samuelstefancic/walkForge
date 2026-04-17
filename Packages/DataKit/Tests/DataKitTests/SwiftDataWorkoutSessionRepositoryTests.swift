// WalkForge — DataKitTests
// Agent-Tests: CRUD + streak sur le repository SwiftData.

@testable import DataKit
import DomainKit
import Foundation
import SwiftData
import Testing

@Suite("SwiftDataWorkoutSessionRepository")
struct SwiftDataWorkoutSessionRepositoryTests {
    private func makeRepository() throws -> SwiftDataWorkoutSessionRepository {
        let container = try ModelContainerFactory.inMemory()
        return SwiftDataWorkoutSessionRepository(modelContainer: container)
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents(year: year, month: month, day: day)
        components.hour = 10
        // swiftlint:disable:next force_unwrapping
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private func makeDTO(
        startDate: Date,
        distanceKm: Double = 1.0,
        durationSeconds: Int = 600,
    ) -> WorkoutSessionDTO {
        WorkoutSessionDTO(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(Double(durationSeconds)),
            durationSeconds: durationSeconds,
            distanceKm: distanceKm,
            estimatedCalories: 50,
            averageSpeedKmh: 3.0,
            maxSpeedKmh: 4.0,
            inclineLevel: 1,
        )
    }

    @Test("save + find + listAll")
    func saveAndRetrieve() async throws {
        let repository = try makeRepository()
        let session = makeDTO(startDate: makeDate(2026, 4, 17))

        try await repository.save(session)

        let found = try await repository.find(id: session.id)
        #expect(found == session)

        let all = try await repository.listAll()
        #expect(all.count == 1)
        #expect(all.first == session)
    }

    @Test("save met à jour si id existant (upsert)")
    func saveUpdates() async throws {
        let repository = try makeRepository()
        let original = makeDTO(startDate: makeDate(2026, 4, 17), distanceKm: 1.0)
        try await repository.save(original)

        let newVersion = WorkoutSessionDTO(
            id: original.id,
            startDate: original.startDate,
            endDate: original.endDate,
            durationSeconds: original.durationSeconds,
            distanceKm: 5.5,
            estimatedCalories: 200,
            averageSpeedKmh: 4.0,
            maxSpeedKmh: 5.0,
            inclineLevel: 2,
        )
        try await repository.save(newVersion)

        let all = try await repository.listAll()
        #expect(all.count == 1, "pas de doublon après update")
        #expect(all.first?.distanceKm == 5.5)
    }

    @Test("delete retire l'entrée")
    func deleteSession() async throws {
        let repository = try makeRepository()
        let session = makeDTO(startDate: makeDate(2026, 4, 17))
        try await repository.save(session)

        try await repository.delete(id: session.id)

        #expect(try await repository.find(id: session.id) == nil)
        #expect(try await repository.listAll().isEmpty)
    }

    @Test("list(from:to:) filtre correctement")
    func dateRangeFilter() async throws {
        let repository = try makeRepository()
        let d1 = makeDate(2026, 4, 10)
        let d2 = makeDate(2026, 4, 15)
        let d3 = makeDate(2026, 4, 20)
        try await repository.save(makeDTO(startDate: d1))
        try await repository.save(makeDTO(startDate: d2))
        try await repository.save(makeDTO(startDate: d3))

        let inRange = try await repository.list(
            from: makeDate(2026, 4, 12),
            to: makeDate(2026, 4, 18),
        )
        #expect(inRange.count == 1)
        #expect(inRange.first?.startDate == d2)
    }

    @Test("currentStreakDays compte les jours consécutifs jusqu'à now")
    func streakIsComputed() async throws {
        let repository = try makeRepository()
        let now = makeDate(2026, 4, 17)
        // Sessions à J, J-1, J-2, J-4 (gap à J-3)
        try await repository.save(makeDTO(startDate: now))
        try await repository.save(makeDTO(startDate: makeDate(2026, 4, 16)))
        try await repository.save(makeDTO(startDate: makeDate(2026, 4, 15)))
        try await repository.save(makeDTO(startDate: makeDate(2026, 4, 13)))

        let streak = try await repository.currentStreakDays(now: now)
        #expect(streak == 3)
    }

    @Test("Streak = 0 si pas de session aujourd'hui")
    func noStreakIfNoSessionToday() async throws {
        let repository = try makeRepository()
        let now = makeDate(2026, 4, 17)
        try await repository.save(makeDTO(startDate: makeDate(2026, 4, 16)))

        let streak = try await repository.currentStreakDays(now: now)
        #expect(streak == 0)
    }
}
