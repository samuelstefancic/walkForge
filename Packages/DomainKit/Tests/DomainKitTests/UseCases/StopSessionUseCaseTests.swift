// WalkForge — DomainKitTests
// Agent-Tests: StopSessionUseCase arrête la session et produit le résumé.

@testable import DomainKit
import Foundation
import Testing

@Suite("StopSessionUseCase")
struct StopSessionUseCaseTests {
    @Test("Résumé depuis le dernier snapshot + historique")
    func summaryFromSnapshots() async throws {
        let service = RecordingBLEService()
        let useCase = StopSessionUseCase(bleService: service)

        let history: [TreadmillData] = [
            .init(speedKmh: 2.0, distanceKm: 0.05, elapsedTimeSeconds: 60),
            .init(speedKmh: 3.0, distanceKm: 0.10, elapsedTimeSeconds: 120),
            .init(speedKmh: 4.0, distanceKm: 0.15, elapsedTimeSeconds: 180),
        ]
        let last: TreadmillData = .init(
            speedKmh: 3.0,
            distanceKm: 0.20,
            elapsedTimeSeconds: 240,
            totalEnergyKcal: 25.0,
        )

        let summary = try await useCase.execute(lastSnapshot: last, history: history)

        #expect(summary.distanceKm == 0.20)
        #expect(summary.durationSeconds == 240)
        #expect(summary.maxSpeedKmh == 4.0)
        #expect(summary.estimatedCalories == 25.0)
        // Moyenne de [2, 3, 4, 3] = 12 / 4 = 3.0
        #expect(summary.averageSpeedKmh == 3.0)

        let calls = await service.calls
        #expect(calls == [.stop])
    }

    @Test("Vitesse nulles exclues de la moyenne")
    func averageExcludesZeroSpeed() async throws {
        let service = RecordingBLEService()
        let useCase = StopSessionUseCase(bleService: service)

        let history: [TreadmillData] = [
            .init(speedKmh: 0.0, distanceKm: 0, elapsedTimeSeconds: 0),
            .init(speedKmh: 4.0, distanceKm: 0.1, elapsedTimeSeconds: 60),
        ]
        let last: TreadmillData = .init(speedKmh: 2.0, distanceKm: 0.15, elapsedTimeSeconds: 120)

        let summary = try await useCase.execute(lastSnapshot: last, history: history)

        // Moyenne de [4, 2] = 3.0 (les 0 sont exclus)
        #expect(summary.averageSpeedKmh == 3.0)
    }

    @Test("Historique vide + vitesse cible > 0 = moyenne sur last")
    func emptyHistoryFallsBackToLast() async throws {
        let service = RecordingBLEService()
        let useCase = StopSessionUseCase(bleService: service)

        let last: TreadmillData = .init(speedKmh: 5.0, distanceKm: 0.5, elapsedTimeSeconds: 300)

        let summary = try await useCase.execute(lastSnapshot: last, history: [])

        #expect(summary.averageSpeedKmh == 5.0)
        #expect(summary.maxSpeedKmh == 5.0)
    }
}
