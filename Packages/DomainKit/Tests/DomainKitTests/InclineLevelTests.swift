// WalkForge — DomainKitTests
// Agent-Tests: validation des niveaux d'inclinaison.
// swiftlint:disable identifier_name

@testable import DomainKit
import Testing

@Suite("InclineLevel")
struct InclineLevelTests {
    @Test
    func `4 niveaux disponibles`() {
        #expect(InclineLevel.allCases.count == 4)
    }

    @Test
    func `Pourcentages croissants`() {
        let percents = InclineLevel.allCases.map(\.percentValue)
        #expect(percents == [0.0, 2.0, 4.0, 6.0])
    }

    @Test
    func `Raw values 0…3`() {
        #expect(InclineLevel.flat.rawValue == 0)
        #expect(InclineLevel.high.rawValue == 3)
    }
}
