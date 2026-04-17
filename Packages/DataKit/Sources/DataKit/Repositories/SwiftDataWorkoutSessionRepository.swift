// WalkForge — DataKit
// Agent-Data: implémentation SwiftData du WorkoutSessionRepository.

import DomainKit
import Foundation
import SwiftData

/// Implémentation SwiftData de `WorkoutSessionRepository`.
///
/// `@ModelActor` génère automatiquement :
/// - un `modelContext` isolé dans l'actor
/// - un `init(modelContainer: ModelContainer)` qui crée un contexte
///   background-safe à partir du container
///
/// Les appels passent par des hops vers l'actor → sûrs depuis n'importe quel
/// contexte async, y compris `@MainActor`.
@ModelActor
public actor SwiftDataWorkoutSessionRepository: WorkoutSessionRepository {
    public func save(_ session: WorkoutSessionDTO) async throws {
        let targetID = session.id
        let descriptor = FetchDescriptor<WorkoutSessionModel>(
            predicate: #Predicate { $0.id == targetID },
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: session)
        } else {
            modelContext.insert(WorkoutSessionModel(from: session))
        }
        try modelContext.save()
    }

    public func listAll() async throws -> [WorkoutSessionDTO] {
        let descriptor = FetchDescriptor<WorkoutSessionModel>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)],
        )
        return try modelContext.fetch(descriptor).map { $0.toDTO() }
    }

    public func list(from: Date, to: Date) async throws -> [WorkoutSessionDTO] {
        let fromDate = from
        let toDate = to
        let descriptor = FetchDescriptor<WorkoutSessionModel>(
            predicate: #Predicate { $0.startDate >= fromDate && $0.startDate <= toDate },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)],
        )
        return try modelContext.fetch(descriptor).map { $0.toDTO() }
    }

    public func find(id: UUID) async throws -> WorkoutSessionDTO? {
        let targetID = id
        let descriptor = FetchDescriptor<WorkoutSessionModel>(
            predicate: #Predicate { $0.id == targetID },
        )
        return try modelContext.fetch(descriptor).first?.toDTO()
    }

    public func delete(id: UUID) async throws {
        let targetID = id
        let descriptor = FetchDescriptor<WorkoutSessionModel>(
            predicate: #Predicate { $0.id == targetID },
        )
        if let model = try modelContext.fetch(descriptor).first {
            modelContext.delete(model)
            try modelContext.save()
        }
    }

    public func currentStreakDays(now: Date) async throws -> Int {
        let sessions = try await listAll()
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar(identifier: .gregorian)
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startDate) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
