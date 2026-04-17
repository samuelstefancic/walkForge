// WalkForge — DomainKit
// Agent-Domain: contrat de planification/envoi de notifications locales.
// Sera implémenté par NotificationKit (Sprint 3).

import Foundation

/// Contenu d'une notification locale planifiable.
///
/// Types exhaustifs consommés par la couche Presentation et par les use cases
/// (ex: `MaintenanceAlertUseCase` planifie une notification `.lubricationDue`).
public enum WalkForgeNotification: Sendable, Equatable, Hashable {
    /// Résumé de fin de session : distance + calories.
    case sessionSummary(distanceKm: Double, calories: Double)

    /// Objectif du jour atteint (pas ou distance).
    case dailyGoalReached

    /// Pause moteur recommandée après X minutes de session continue.
    case motorRest(elapsedMinutes: Int)

    /// Lubrification du tapis recommandée.
    case lubricationDue

    /// Rappel d'une session planifiée (programme).
    case scheduledProgramReminder(programID: UUID, programName: String)
}

/// État de la permission Notifications.
public enum NotificationAuthorization: Sendable, Equatable, Hashable {
    case notDetermined
    case denied
    case authorized
    case provisional
}

/// Contrat du service de notifications.
///
/// Implémenté par `NotificationKit.UserNotificationsService` (Sprint 3).
/// Un mock (`InMemoryNotificationService`) est utilisé en tests.
public protocol NotificationServiceProtocol: Sendable {
    /// État actuel de la permission.
    func authorizationStatus() async -> NotificationAuthorization

    /// Demande la permission à l'utilisateur. Retourne l'état après décision.
    func requestAuthorization() async -> NotificationAuthorization

    /// Planifie une notification pour une date donnée.
    /// L'`id` permet une mise à jour/annulation ultérieure (idempotence).
    func schedule(_ notification: WalkForgeNotification, at date: Date, id: String) async throws

    /// Envoie immédiatement (sans planification).
    func fireNow(_ notification: WalkForgeNotification, id: String) async throws

    /// Annule une notification planifiée ou délivrée.
    func cancel(id: String) async

    /// Annule toutes les notifications WalkForge planifiées.
    func cancelAll() async
}
