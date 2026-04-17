// WalkForge — DomainKitTests
// Agent-Tests: SetTargetSpeedUseCase valide + snap + envoie FTMS.

@testable import DomainKit
import Testing

@Suite("SetTargetSpeedUseCase")
struct SetTargetSpeedUseCaseTests {
    @Test("Vitesse alignée sur le pas : envoyée telle quelle")
    func alignedSpeed() async throws {
        let service = RecordingBLEService()
        let useCase = SetTargetSpeedUseCase(bleService: service)

        let snapped = try await useCase.execute(kmh: 3.5)

        #expect(snapped == 3.5)
        let calls = await service.calls
        #expect(calls == [.setTargetSpeed(3.5)])
    }

    @Test("Vitesse non alignée : snap au pas le plus proche")
    func nonAlignedIsSnapped() async throws {
        let service = RecordingBLEService()
        let useCase = SetTargetSpeedUseCase(bleService: service)

        // 3.76 → snap → 4.0 (pas 0.5)
        let snapped = try await useCase.execute(kmh: 3.76)

        #expect(snapped == 4.0)
        let calls = await service.calls
        #expect(calls == [.setTargetSpeed(4.0)])
    }

    @Test("Vitesse hors plage basse : clampée à min")
    func belowMinIsClamped() async throws {
        let service = RecordingBLEService()
        let useCase = SetTargetSpeedUseCase(bleService: service)

        let snapped = try await useCase.execute(kmh: 0.1)

        #expect(snapped == 1.0)
        let calls = await service.calls
        #expect(calls == [.setTargetSpeed(1.0)])
    }

    @Test("Vitesse hors plage haute : clampée à max")
    func aboveMaxIsClamped() async throws {
        let service = RecordingBLEService()
        let useCase = SetTargetSpeedUseCase(bleService: service)

        let snapped = try await useCase.execute(kmh: 99.0)

        #expect(snapped == 6.0)
        let calls = await service.calls
        #expect(calls == [.setTargetSpeed(6.0)])
    }

    @Test("Plage custom : step 0.1")
    func customRange() async throws {
        let service = RecordingBLEService()
        let range = SpeedRange(minKmh: 2.0, maxKmh: 10.0, stepKmh: 0.1)
        let useCase = SetTargetSpeedUseCase(bleService: service, range: range)

        let snapped = try await useCase.execute(kmh: 5.03)

        #expect(snapped == 5.0)
    }
}
