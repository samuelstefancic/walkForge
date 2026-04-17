// WalkForge — DomainKit
// Agent-Domain: niveaux d'inclinaison supportés par le tapis PORTENTUM 8 Pro.

import Foundation

/// Niveau d'inclinaison discret du tapis.
///
/// Le PORTENTUM 8 Pro expose 4 niveaux (plat + 3 niveaux). La conversion en
/// pourcentage est approximative et à ajuster après tests hardware réels.
public enum InclineLevel: Int, Sendable, CaseIterable, Equatable, Hashable {
    case flat = 0
    case low = 1
    case medium = 2
    case high = 3

    /// Inclinaison en pourcentage transmise via FTMS `Set Target Inclination`.
    public var percentValue: Double {
        switch self {
        case .flat: 0.0
        case .low: 2.0
        case .medium: 4.0
        case .high: 6.0
        }
    }

    /// Libellé court pour affichage UI.
    public var shortLabel: String {
        switch self {
        case .flat: "0"
        case .low: "1"
        case .medium: "2"
        case .high: "3"
        }
    }
}
