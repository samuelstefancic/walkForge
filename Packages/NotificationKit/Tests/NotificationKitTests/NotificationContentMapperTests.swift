// WalkForge — NotificationKitTests
// Agent-Tests: mapping WalkForgeNotification → titre + corps.

import DomainKit
import Foundation
@testable import NotificationKit
import Testing

@Suite("NotificationContentMapper")
struct NotificationContentMapperTests {
    @Test("sessionSummary formate distance (2 décimales) et calories (entier)")
    func sessionSummary() {
        let rendered = NotificationContentMapper.render(
            .sessionSummary(distanceKm: 1.234, calories: 125.7),
        )
        #expect(rendered.title.contains("Session terminée"))
        #expect(rendered.body.contains("1.23"))
        #expect(rendered.body.contains("126"))
    }

    @Test("dailyGoalReached — titre + corps non vides")
    func goalReached() {
        let rendered = NotificationContentMapper.render(.dailyGoalReached)
        #expect(!rendered.title.isEmpty)
        #expect(!rendered.body.isEmpty)
    }

    @Test("motorRest injecte la durée en minutes")
    func motorRest() {
        let rendered = NotificationContentMapper.render(.motorRest(elapsedMinutes: 95))
        #expect(rendered.body.contains("95"))
    }

    @Test("lubricationDue — titre + corps")
    func lubricationDue() {
        let rendered = NotificationContentMapper.render(.lubricationDue)
        #expect(rendered.title.contains("Lubrification"))
    }

    @Test("scheduledProgramReminder injecte le nom du programme")
    func programReminder() {
        let rendered = NotificationContentMapper.render(
            .scheduledProgramReminder(programID: UUID(), programName: "Marche matinale"),
        )
        #expect(rendered.body.contains("Marche matinale"))
    }
}
