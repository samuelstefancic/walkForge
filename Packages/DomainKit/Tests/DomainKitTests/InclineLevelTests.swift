// WalkForge — DomainKitTests
// Agent-Tests: validation des niveaux d'inclinaison.

@testable import DomainKit
import Testing

@Suite("InclineLevel")
struct InclineLevelTests {
    @Test("4 niveaux disponibles")
    func fourCases() {
        #expect(InclineLevel.allCases.count == 4)
    }

    @Test("Pourcentages croissants 0/2/4/6")
    func ascendingPercent() {
        let percents = InclineLevel.allCases.map(\.percentValue)
        #expect(percents == [0.0, 2.0, 4.0, 6.0])
    }

    @Test("Raw values 0 à 3")
    func rawValues() {
        #expect(InclineLevel.flat.rawValue == 0)
        #expect(InclineLevel.high.rawValue == 3)
    }
}
