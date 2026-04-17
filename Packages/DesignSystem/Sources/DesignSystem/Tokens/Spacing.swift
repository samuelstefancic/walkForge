// WalkForge — DesignSystem
// Agent-UI: échelle d'espacement 4-based (Apple HIG compatible).

import CoreFoundation

/// Échelle d'espacement utilisée partout dans l'UI.
public enum WFSpacing {
    /// 4 pt — espacement minimum (entre icône et texte adjacents).
    public static let xs: CGFloat = 4
    /// 8 pt.
    public static let sm: CGFloat = 8
    /// 12 pt.
    public static let md: CGFloat = 12
    /// 16 pt — marges d'écran standard.
    public static let lg: CGFloat = 16
    /// 24 pt — séparation entre sections.
    public static let xl: CGFloat = 24
    /// 32 pt.
    public static let xxl: CGFloat = 32
    /// 48 pt — espacement titre/contenu majeur.
    public static let xxxl: CGFloat = 48
}

/// Rayon de coin standard pour les composants.
public enum WFCornerRadius {
    /// 8 pt — boutons, pills.
    public static let small: CGFloat = 8
    /// 16 pt — cartes métriques.
    public static let medium: CGFloat = 16
    /// 24 pt — conteneurs principaux.
    public static let large: CGFloat = 24
}
