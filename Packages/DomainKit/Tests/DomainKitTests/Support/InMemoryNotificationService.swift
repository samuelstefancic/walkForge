// WalkForge — DomainKitTests
// Agent-Tests: mock actor-isolé de NotificationServiceProtocol.

@testable import DomainKit
import Foundation

actor InMemoryNotificationService: NotificationServiceProtocol {
    struct ScheduledNotification: Equatable {
        let id: String
        let notification: WalkForgeNotification
        let date: Date?
    }

    var scheduled: [ScheduledNotification] = []
    var fired: [ScheduledNotification] = []
    var cancelled: [String] = []
    var authorizationToReturn: NotificationAuthorization = .authorized
    var authorizationRequested = false
    var errorToThrow: (any Error)?

    func authorizationStatus() async -> NotificationAuthorization {
        authorizationToReturn
    }

    func requestAuthorization() async -> NotificationAuthorization {
        authorizationRequested = true
        return authorizationToReturn
    }

    func schedule(_ notification: WalkForgeNotification, at date: Date, id: String) async throws {
        if let errorToThrow { throw errorToThrow }
        scheduled.append(.init(id: id, notification: notification, date: date))
    }

    func fireNow(_ notification: WalkForgeNotification, id: String) async throws {
        if let errorToThrow { throw errorToThrow }
        fired.append(.init(id: id, notification: notification, date: nil))
    }

    func cancel(id: String) async {
        cancelled.append(id)
        scheduled.removeAll { $0.id == id }
    }

    func cancelAll() async {
        cancelled.append(contentsOf: scheduled.map(\.id))
        scheduled.removeAll()
    }
}
