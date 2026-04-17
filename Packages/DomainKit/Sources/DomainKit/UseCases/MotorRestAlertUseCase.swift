// WalkForge — DomainKit
// Agent-Domain: détection de sessions trop longues → alerte pause moteur.

import Foundation

/// Use case de vérification de la durée cumulée d'une session.
///
/// Règle : après 90 minutes de session continue, déclencher une notification
/// pour inviter l'utilisateur à mettre le tapis en pause (protection moteur).
///
/// Une seule notification par session : le caller doit réinitialiser son
/// flag "alerte émise" entre deux sessions.
public struct MotorRestAlertUseCase: Sendable {
    /// Seuil en minutes déclenchant l'alerte.
    public static let motorRestThresholdMinutes = 90

    private let notificationService: any NotificationServiceProtocol

    public init(notificationService: any NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Vérifie si une alerte doit être déclenchée.
    ///
    /// - Parameter elapsedSeconds: durée écoulée depuis le début de session.
    /// - Returns: `true` si l'alerte a été émise (seuil atteint pour la 1re fois).
    @discardableResult
    public func evaluate(elapsedSeconds: Int, alreadyAlerted: Bool) async throws -> Bool {
        guard !alreadyAlerted else { return false }
        let elapsedMinutes = elapsedSeconds / 60
        guard elapsedMinutes >= Self.motorRestThresholdMinutes else { return false }

        try await notificationService.fireNow(
            .motorRest(elapsedMinutes: elapsedMinutes),
            id: "motor.rest.current",
        )
        return true
    }
}
