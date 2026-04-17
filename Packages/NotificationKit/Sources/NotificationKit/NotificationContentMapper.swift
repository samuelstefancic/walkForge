// WalkForge — NotificationKit
// Agent-Infra: conversion WalkForgeNotification → UNNotificationContent.

import DomainKit
import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Mapper pur (testable hors iOS) qui produit titre + corps pour une notification.
///
/// Pas de dépendance à UserNotifications : le mapping peut être testé
/// sur n'importe quelle plateforme. Le `UserNotificationsService` consomme
/// ce mapping pour construire le `UNMutableNotificationContent`.
public enum NotificationContentMapper {
    public struct Rendered: Sendable, Equatable {
        public let title: String
        public let body: String
    }

    public static func render(_ notification: WalkForgeNotification) -> Rendered {
        switch notification {
        case let .sessionSummary(distanceKm, calories):
            Rendered(
                title: "Session terminée 🏆",
                body: String(
                    format: "Vous avez parcouru %.2f km et dépensé %.0f kcal.",
                    distanceKm,
                    calories,
                ),
            )

        case .dailyGoalReached:
            Rendered(
                title: "Objectif atteint ! 🎯",
                body: "Bravo, vous avez atteint votre objectif quotidien.",
            )

        case let .motorRest(elapsedMinutes):
            Rendered(
                title: "Pause moteur recommandée",
                body: "\(elapsedMinutes) min de session continue. Pensez à une pause pour protéger le tapis.",
            )

        case .lubricationDue:
            Rendered(
                title: "Lubrification recommandée 🛠️",
                body: "Il est temps de lubrifier la bande du tapis (toutes les 3 semaines).",
            )

        case let .scheduledProgramReminder(_, programName):
            Rendered(
                title: "Programme prêt ⏰",
                body: "C'est l'heure de votre programme \"\(programName)\".",
            )
        }
    }
}
