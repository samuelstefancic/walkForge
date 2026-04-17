// WalkForge — DesignSystem
// Agent-UI: hiérarchie typographique alignée sur les SF Pro familles.

import SwiftUI

/// Typographie WalkForge.
///
/// - Titres : SF Pro Display
/// - Métriques affichées en gros chiffres : SF Pro Rounded
/// - Valeurs numériques fixes (tables, chronos) : SF Mono
public enum WFFont {
    /// Titre principal écran (ex. "Session").
    public static var screenTitle: Font {
        .system(size: 34, weight: .bold, design: .default)
    }

    /// Sous-titre (ex. "Connecté à PORTENTUM").
    public static var subtitle: Font {
        .system(size: 17, weight: .medium, design: .default)
    }

    /// Valeur métrique XL (ex. vitesse instantanée).
    public static var metricXL: Font {
        .system(size: 72, weight: .bold, design: .rounded).monospacedDigit()
    }

    /// Valeur métrique moyenne (ex. distance, calories).
    public static var metricM: Font {
        .system(size: 32, weight: .semibold, design: .rounded).monospacedDigit()
    }

    /// Label associé à une métrique ("km", "kcal").
    public static var metricLabel: Font {
        .system(size: 13, weight: .medium, design: .default)
    }

    /// Chrono (monospaced pour éviter le saut des chiffres).
    public static var timer: Font {
        .system(size: 44, weight: .medium, design: .monospaced).monospacedDigit()
    }

    /// Corps de texte courant.
    public static var body: Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    /// Caption (légende, mention).
    public static var caption: Font {
        .system(size: 12, weight: .regular, design: .default)
    }
}
