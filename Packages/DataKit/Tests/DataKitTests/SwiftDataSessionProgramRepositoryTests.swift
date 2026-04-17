// WalkForge — DataKitTests
// Agent-Tests: CRUD des programmes avec étapes.

@testable import DataKit
import DomainKit
import Foundation
import Testing

@Suite("SwiftDataSessionProgramRepository")
struct SwiftDataSessionProgramRepositoryTests {
    private func makeRepository() throws -> SwiftDataSessionProgramRepository {
        let container = try ModelContainerFactory.inMemory()
        return SwiftDataSessionProgramRepository(modelContainer: container)
    }

    private func makeProgram(name: String = "Marche 15 min") -> SessionProgramDTO {
        SessionProgramDTO(
            name: name,
            type: .timer,
            steps: [
                ProgramStepDTO(targetSpeedKmh: 3.0, durationSeconds: 900, inclineLevel: 0),
            ],
        )
    }

    @Test("save + find avec steps préservées")
    func saveWithSteps() async throws {
        let repository = try makeRepository()
        let program = makeProgram()

        try await repository.save(program)

        let found = try await repository.find(id: program.id)
        #expect(found?.name == program.name)
        #expect(found?.steps.count == 1)
        #expect(found?.steps.first?.targetSpeedKmh == 3.0)
    }

    @Test("listAll trié par nom")
    func listSortedByName() async throws {
        let repository = try makeRepository()
        try await repository.save(makeProgram(name: "Zèbre"))
        try await repository.save(makeProgram(name: "Alpha"))
        try await repository.save(makeProgram(name: "Marcher"))

        let all = try await repository.listAll()
        #expect(all.map(\.name) == ["Alpha", "Marcher", "Zèbre"])
    }

    @Test("delete retire le programme")
    func deleteProgram() async throws {
        let repository = try makeRepository()
        let program = makeProgram()
        try await repository.save(program)

        try await repository.delete(id: program.id)
        #expect(try await repository.find(id: program.id) == nil)
    }

    @Test("save met à jour si même id (upsert)")
    func saveUpserts() async throws {
        let repository = try makeRepository()
        let program = makeProgram(name: "Original")
        try await repository.save(program)

        var updated = program
        updated.name = "Renommé"
        try await repository.save(updated)

        let all = try await repository.listAll()
        #expect(all.count == 1)
        #expect(all.first?.name == "Renommé")
    }
}
