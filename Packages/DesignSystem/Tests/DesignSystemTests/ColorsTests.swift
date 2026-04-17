// WalkForge — DesignSystemTests
// Agent-Tests: vérifie que la palette est valide (couleurs non identiques entre rôles).

@testable import DesignSystem
import SwiftUI
import Testing

@Suite("WFColor · palette")
struct ColorsTests {
    @Test("Toutes les couleurs principales sont distinctes")
    func distinctColors() {
        let colors: [String] = [
            String(describing: WFColor.backgroundPrimary),
            String(describing: WFColor.backgroundSecondary),
            String(describing: WFColor.accentPrimary),
            String(describing: WFColor.accentSecondary),
            String(describing: WFColor.success),
            String(describing: WFColor.warning),
            String(describing: WFColor.danger),
        ]
        let unique = Set(colors)
        #expect(unique.count == colors.count, "Deux couleurs partagent la même représentation")
    }
}
