// WalkForge — DomainKit
// Agent-Domain: calcul de la prochaine alerte lubrification tapis.

import Foundation

/// Résultat du calcul de maintenance.
public struct MaintenanceAlert: Sendable, Equatable, Hashable {
    /// Prochaine date à laquelle lubrifier.
    public let dueDate: Date
    /// `true` si la date est dépassée à la date de référence.
    public let isOverdue: Bool
    /// Notification à planifier (identifiant stable `"maintenance.lubrication"`).
    public let notificationID: String
    public let notification: WalkForgeNotification

    public init(dueDate: Date, isOverdue: Bool) {
        self.dueDate = dueDate
        self.isOverdue = isOverdue
        notificationID = "maintenance.lubrication"
        notification = .lubricationDue
    }
}

/// Use case de calcul d'alerte lubrification.
///
/// Règle : lubrifier toutes les 3 semaines en usage intensif. La prochaine
/// échéance = `dernière lubrification + 21 jours` (ou `now + 21j` si aucune
/// lubrification enregistrée jusqu'à présent).
///
/// Planifie également la notification locale correspondante via le
/// `NotificationServiceProtocol`.
public struct MaintenanceAlertUseCase: Sendable {
    /// Intervalle de lubrification en jours.
    public static let lubricationIntervalDays = 21

    private let notificationService: any NotificationServiceProtocol
    private let calendar: Calendar

    public init(
        notificationService: any NotificationServiceProtocol,
        calendar: Calendar = .autoupdatingCurrent,
    ) {
        self.notificationService = notificationService
        self.calendar = calendar
    }

    /// Calcule la prochaine date de lubrification et planifie la notification.
    ///
    /// - Parameters:
    ///   - lastLubricationDate: date de la dernière lubrification, ou `nil`
    ///     (tapis neuf / premier usage).
    ///   - now: date de référence (injectable pour tests).
    /// - Returns: l'alerte calculée.
    public func execute(
        lastLubricationDate: Date?,
        now: Date = Date(),
    ) async throws -> MaintenanceAlert {
        let reference = lastLubricationDate ?? now
        guard let dueDate = calendar.date(
            byAdding: .day,
            value: Self.lubricationIntervalDays,
            to: reference,
        ) else {
            throw MaintenanceAlertError.dateArithmeticFailure
        }
        let alert = MaintenanceAlert(dueDate: dueDate, isOverdue: dueDate < now)

        if alert.isOverdue {
            try await notificationService.fireNow(alert.notification, id: alert.notificationID)
        } else {
            try await notificationService.schedule(
                alert.notification,
                at: alert.dueDate,
                id: alert.notificationID,
            )
        }
        return alert
    }
}

/// Erreur spécifique au use case (rare, uniquement si `Calendar` refuse l'arithmétique).
public enum MaintenanceAlertError: Error, Sendable, Equatable {
    case dateArithmeticFailure
}
