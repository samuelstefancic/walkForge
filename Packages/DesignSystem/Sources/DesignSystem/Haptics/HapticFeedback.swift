// WalkForge — DesignSystem
// Agent-UI: wrapper thread-safe sur UIFeedbackGenerator.
// iOS uniquement — no-op sur les autres plateformes pour garder le build cross-platform.

#if canImport(UIKit)
import UIKit
#endif

/// Wrapper haptic feedback, actor-isolé pour être appelable en toute sécurité
/// depuis n'importe quel contexte async.
///
/// - Note : tous les appels sont `nonisolated` pour éviter des hops inutiles.
///   `UIFeedbackGenerator` doit être utilisé depuis le main thread, donc
///   chaque appel hop sur `MainActor`.
public enum WFHaptic: Sendable {
    /// Démarrage de session : impact medium.
    case sessionStart
    /// Arrêt de session : impact rigid.
    case sessionStop
    /// Changement de vitesse : selection changed.
    case speedChanged
    /// Changement d'inclinaison : selection changed.
    case inclineChanged
    /// Objectif atteint : notification success.
    case goalReached
    /// Erreur : notification error.
    case error

    /// Déclenche le retour haptique (thread-safe).
    @MainActor
    public func play() {
        #if canImport(UIKit) && os(iOS)
        switch self {
        case .sessionStart:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .sessionStop:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .speedChanged, .inclineChanged:
            UISelectionFeedbackGenerator().selectionChanged()
        case .goalReached:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
