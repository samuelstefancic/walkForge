// WalkForge — DomainKitTests
// Agent-Tests: seuil 90 min → alerte pause moteur (idempotente par session).

@testable import DomainKit
import Testing

@Suite("MotorRestAlertUseCase")
struct MotorRestAlertUseCaseTests {
    @Test("Sous 90 min : pas d'alerte")
    func belowThreshold() async throws {
        let service = InMemoryNotificationService()
        let useCase = MotorRestAlertUseCase(notificationService: service)

        let fired = try await useCase.evaluate(elapsedSeconds: 89 * 60, alreadyAlerted: false)

        #expect(!fired)
        let firedCount = await service.fired.count
        #expect(firedCount == 0)
    }

    @Test("Pile 90 min : alerte déclenchée")
    func atThreshold() async throws {
        let service = InMemoryNotificationService()
        let useCase = MotorRestAlertUseCase(notificationService: service)

        let fired = try await useCase.evaluate(elapsedSeconds: 90 * 60, alreadyAlerted: false)

        #expect(fired)
        let firedCount = await service.fired.count
        #expect(firedCount == 1)
    }

    @Test("Au-delà mais déjà alerté : pas de doublon")
    func alreadyAlertedNoDouble() async throws {
        let service = InMemoryNotificationService()
        let useCase = MotorRestAlertUseCase(notificationService: service)

        let fired = try await useCase.evaluate(elapsedSeconds: 120 * 60, alreadyAlerted: true)

        #expect(!fired)
        let firedCount = await service.fired.count
        #expect(firedCount == 0)
    }
}
