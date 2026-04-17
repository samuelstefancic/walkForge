// WalkForge — DomainKitTests
// Agent-Tests: mock actor-isolé de WorkoutSessionRepository.

@testable import DomainKit
import Foundation

actor InMemoryWorkoutSessionRepository: WorkoutSessionRepository {
    var storage: [UUID: WorkoutSessionDTO] = [:]
    var errorToThrow: (any Error)?

    func save(_ session: WorkoutSessionDTO) async throws {
        if let errorToThrow { throw errorToThrow }
        storage[session.id] = session
    }

    func listAll() async throws -> [WorkoutSessionDTO] {
        Array(storage.values).sorted { $0.startDate > $1.startDate }
    }

    func list(from: Date, to: Date) async throws -> [WorkoutSessionDTO] {
        try await listAll().filter { $0.startDate >= from && $0.startDate <= to }
    }

    func find(id: UUID) async throws -> WorkoutSessionDTO? {
        storage[id]
    }

    func delete(id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    func currentStreakDays(now: Date) async throws -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let days = Set(storage.values.map { calendar.startOfDay(for: $0.startDate) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
