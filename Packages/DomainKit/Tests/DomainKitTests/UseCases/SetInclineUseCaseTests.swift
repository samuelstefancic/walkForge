// WalkForge — DomainKitTests
// Agent-Tests: SetInclineUseCase mappe le niveau discret vers le pourcentage.

@testable import DomainKit
import Testing

@Suite("SetInclineUseCase")
struct SetInclineUseCaseTests {
    @Test("Chaque niveau envoie son pourcentage correspondant", arguments: InclineLevel.allCases)
    func levelMapping(level: InclineLevel) async throws {
        let service = RecordingBLEService()
        let useCase = SetInclineUseCase(bleService: service)

        try await useCase.execute(level: level)

        let calls = await service.calls
        #expect(calls == [.setTargetInclination(level.percentValue)])
    }
}
