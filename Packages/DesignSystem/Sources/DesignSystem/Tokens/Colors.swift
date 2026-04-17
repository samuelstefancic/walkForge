// WalkForge — DesignSystem
// Agent-UI: palette dark mode premium.
//
// Hex → SwiftUI.Color conversion via initialiseur ci-dessous.

import SwiftUI

/// Palette de couleurs WalkForge (dark mode only dans la v1, light futur).
public enum WFColor {
    /// Background principal, quasi-noir : `#0A0A0F`.
    public static let backgroundPrimary: Color = .init(hex: 0x0A0A0F)

    /// Background secondaire pour les cartes : `#13131C`.
    public static let backgroundSecondary: Color = .init(hex: 0x13131C)

    /// Accent principal, cyan électrique : `#00E5FF`.
    public static let accentPrimary: Color = .init(hex: 0x00E5FF)

    /// Accent secondaire, violet premium : `#7B2FFF`.
    public static let accentSecondary: Color = .init(hex: 0x7B2FFF)

    /// Vert succès : `#00FF94`.
    public static let success: Color = .init(hex: 0x00FF94)

    /// Orange avertissement : `#FF9500`.
    public static let warning: Color = .init(hex: 0xFF9500)

    /// Rouge danger : `#FF3B30`.
    public static let danger: Color = .init(hex: 0xFF3B30)

    /// Texte primaire : `#FFFFFF`.
    public static let textPrimary: Color = .init(hex: 0xFFFFFF)

    /// Texte secondaire : `#8E8EA0`.
    public static let textSecondary: Color = .init(hex: 0x8E8EA0)
}

// MARK: - Hex init

extension Color {
    /// Initialise une couleur depuis un entier hexadécimal RGB (ex. `0xFF3B30`).
    /// Opacité toujours 1.0.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}
