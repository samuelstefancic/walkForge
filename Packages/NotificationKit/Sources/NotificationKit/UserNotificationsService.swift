// WalkForge — NotificationKit
// Agent-Infra: implémentation UserNotifications du NotificationServiceProtocol.
//
// - Conditionnée sur `canImport(UserNotifications)` pour rester compilable sur
//   Linux et autres plateformes (no-op si non dispo).
// - `@preconcurrency import UserNotifications` : les types Apple
//   (UNNotificationSettings, etc.) ne sont pas encore Sendable sur les SDKs
//   antérieurs à macOS 26 / iOS 19. Les appels sont faits depuis un actor
//   → sûrs en pratique.

import DomainKit
import Foundation
import os
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

/// Service de notifications utilisant `UserNotifications`.
///
/// - Note : préfère `UNCalendarNotificationTrigger` (stable aux redémarrages
///   de l'appareil) plutôt que `UNTimeIntervalNotificationTrigger`.
public actor UserNotificationsService: NotificationServiceProtocol {
    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "NotificationKit")

    public init() {}

    public func authorizationStatus() async -> NotificationAuthorization {
        #if canImport(UserNotifications)
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return Self.mapAuthorization(settings.authorizationStatus)
        #else
        return .notDetermined
        #endif
    }

    public func requestAuthorization() async -> NotificationAuthorization {
        #if canImport(UserNotifications)
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            logger.error("Authorization request failed: \(String(describing: error), privacy: .public)")
        }
        return await authorizationStatus()
        #else
        return .notDetermined
        #endif
    }

    public func schedule(
        _ notification: WalkForgeNotification,
        at date: Date,
        id: String,
    ) async throws {
        #if canImport(UserNotifications)
        let rendered = NotificationContentMapper.render(notification)
        let content = UNMutableNotificationContent()
        content.title = rendered.title
        content.body = rendered.body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date,
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
        logger.info("Scheduled \(id, privacy: .public) at \(date, privacy: .public)")
        #endif
    }

    public func fireNow(_ notification: WalkForgeNotification, id: String) async throws {
        #if canImport(UserNotifications)
        let rendered = NotificationContentMapper.render(notification)
        let content = UNMutableNotificationContent()
        content.title = rendered.title
        content.body = rendered.body
        content.sound = .default

        // 1 seconde plutôt que nil : certaines versions d'iOS refusent un
        // trigger nil ou un delay nul.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
        logger.info("Fired \(id, privacy: .public) immediately")
        #endif
    }

    public func cancel(id: String) async {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        #endif
    }

    public func cancelAll() async {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        #endif
    }

    #if canImport(UserNotifications)
    private static func mapAuthorization(_ status: UNAuthorizationStatus) -> NotificationAuthorization {
        switch status {
        case .authorized: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        case .provisional: .provisional
        case .ephemeral: .authorized
        @unknown default: .notDetermined
        }
    }
    #endif
}
