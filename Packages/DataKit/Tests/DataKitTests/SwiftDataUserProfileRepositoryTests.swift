// WalkForge — DataKitTests
// Agent-Tests: singleton du profil utilisateur (upsert).

@testable import DataKit
import DomainKit
import Foundation
import Testing

@Suite("SwiftDataUserProfileRepository")
struct SwiftDataUserProfileRepositoryTests {
    private func makeRepository() throws -> SwiftDataUserProfileRepository {
        let container = try ModelContainerFactory.inMemory()
        return SwiftDataUserProfileRepository(modelContainer: container)
    }

    @Test("load sur container vide → nil")
    func loadEmpty() async throws {
        let repository = try makeRepository()
        let loaded = try await repository.load()
        #expect(loaded == nil)
    }

    @Test("save + load round-trip")
    func saveAndLoad() async throws {
        let repository = try makeRepository()
        let profile = UserProfileDTO(weightKg: 75, heightCm: 180, ageYears: 30)
        try await repository.save(profile)

        let loaded = try await repository.load()
        #expect(loaded?.weightKg == 75)
        #expect(loaded?.heightCm == 180)
        #expect(loaded?.ageYears == 30)
    }

    @Test("save deux fois : pas de doublon (singleton)")
    func saveSingleton() async throws {
        let repository = try makeRepository()
        try await repository.save(UserProfileDTO(weightKg: 70, heightCm: 175, ageYears: 28))
        try await repository.save(UserProfileDTO(weightKg: 72, heightCm: 175, ageYears: 29))

        let loaded = try await repository.load()
        #expect(loaded?.weightKg == 72)
        #expect(loaded?.ageYears == 29)
    }
}
