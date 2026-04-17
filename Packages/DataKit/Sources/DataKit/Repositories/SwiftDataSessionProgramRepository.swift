// WalkForge — DataKit
// Agent-Data: implémentation SwiftData du SessionProgramRepository.

import DomainKit
import Foundation
import SwiftData

@ModelActor
public actor SwiftDataSessionProgramRepository: SessionProgramRepository {
    public func listAll() async throws -> [SessionProgramDTO] {
        let descriptor = FetchDescriptor<SessionProgramModel>(
            sortBy: [SortDescriptor(\.name)],
        )
        return try modelContext.fetch(descriptor).map { $0.toDTO() }
    }

    public func save(_ program: SessionProgramDTO) async throws {
        let targetID = program.id
        let descriptor = FetchDescriptor<SessionProgramModel>(
            predicate: #Predicate { $0.id == targetID },
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: program)
        } else {
            modelContext.insert(SessionProgramModel.from(dto: program))
        }
        try modelContext.save()
    }

    public func delete(id: UUID) async throws {
        let targetID = id
        let descriptor = FetchDescriptor<SessionProgramModel>(
            predicate: #Predicate { $0.id == targetID },
        )
        if let model = try modelContext.fetch(descriptor).first {
            modelContext.delete(model)
            try modelContext.save()
        }
    }

    public func find(id: UUID) async throws -> SessionProgramDTO? {
        let targetID = id
        let descriptor = FetchDescriptor<SessionProgramModel>(
            predicate: #Predicate { $0.id == targetID },
        )
        return try modelContext.fetch(descriptor).first?.toDTO()
    }
}
