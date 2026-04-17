// WalkForge — DomainKitTests
// Agent-Tests: StartSessionUseCase orchestre requestControl + start.

@testable import DomainKit
import Testing

@Suite("StartSessionUseCase")
struct StartSessionUseCaseTests {
    @Test("Happy path : requestControl puis start dans l'ordre")
    func happyPath() async throws {
        let service = RecordingBLEService()
        let useCase = StartSessionUseCase(bleService: service)

        try await useCase.execute()

        let calls = await service.calls
        #expect(calls == [.requestControl, .start])
    }

    @Test("Échec de requestControl : start n'est jamais appelé")
    func failOnRequestControl() async {
        let service = RecordingBLEService()
        await service.setError(.controlNotGranted)
        let useCase = StartSessionUseCase(bleService: service)

        await #expect(throws: TreadmillError.controlNotGranted) {
            try await useCase.execute()
        }

        let calls = await service.calls
        #expect(calls == [.requestControl])
    }
}
