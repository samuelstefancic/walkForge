// WalkForge — DomainKitTests
// Agent-Tests: règle de lubrification à 21 jours.

@testable import DomainKit
import Foundation
import Testing

@Suite("MaintenanceAlertUseCase")
struct MaintenanceAlertUseCaseTests {
    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        // swiftlint:disable:next force_unwrapping
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    @Test("Sans date précédente : due = now + 21 jours, non overdue")
    func freshDevice() async throws {
        let service = InMemoryNotificationService()
        let useCase = MaintenanceAlertUseCase(notificationService: service)
        let now = makeDate(2026, 4, 17)

        let alert = try await useCase.execute(lastLubricationDate: nil, now: now)

        let expected = makeDate(2026, 5, 8) // 21 jours plus tard
        #expect(alert.dueDate == expected)
        #expect(!alert.isOverdue)

        let scheduled = await service.scheduled
        #expect(scheduled.count == 1)
        #expect(scheduled.first?.id == "maintenance.lubrication")
        #expect(scheduled.first?.notification == .lubricationDue)
    }

    @Test("Dernière lubrification il y a 10 jours : due dans 11 jours, planifié")
    func notYetDue() async throws {
        let service = InMemoryNotificationService()
        let useCase = MaintenanceAlertUseCase(notificationService: service)
        let now = makeDate(2026, 4, 17)
        let lastLubed = makeDate(2026, 4, 7) // -10 jours

        let alert = try await useCase.execute(lastLubricationDate: lastLubed, now: now)

        let expected = makeDate(2026, 4, 28)
        #expect(alert.dueDate == expected)
        #expect(!alert.isOverdue)
        let scheduledCount = await service.scheduled.count
        let firedCount = await service.fired.count
        #expect(scheduledCount == 1)
        #expect(firedCount == 0)
    }

    @Test("Dernière lubrification il y a 30 jours : overdue → fireNow")
    func overdueFiresImmediately() async throws {
        let service = InMemoryNotificationService()
        let useCase = MaintenanceAlertUseCase(notificationService: service)
        let now = makeDate(2026, 4, 17)
        let lastLubed = makeDate(2026, 3, 18) // -30 jours

        let alert = try await useCase.execute(lastLubricationDate: lastLubed, now: now)

        #expect(alert.isOverdue)
        let fired = await service.fired
        #expect(fired.count == 1)
        #expect(fired.first?.notification == .lubricationDue)
    }
}
