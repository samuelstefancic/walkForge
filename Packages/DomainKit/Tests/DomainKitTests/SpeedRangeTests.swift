// WalkForge — DomainKitTests
// Agent-Tests: validation de la logique de plage de vitesse.

@testable import DomainKit
import Testing

@Suite("SpeedRange")
struct SpeedRangeTests {
    @Test("PORTENTUM 8 Pro: plage 1–6 km/h par pas de 0.5")
    func portentumRange() {
        let range = SpeedRange.portentum8Pro
        #expect(range.minKmh == 1.0)
        #expect(range.maxKmh == 6.0)
        #expect(range.stepKmh == 0.5)
    }

    @Test("isValid accepte les vitesses alignées sur le pas")
    func validSpeeds() {
        let range = SpeedRange.portentum8Pro
        for speed in stride(from: 1.0, through: 6.0, by: 0.5) {
            #expect(range.isValid(speed), "attendu valide: \(speed)")
        }
    }

    @Test("isValid rejette hors plage")
    func invalidOutOfRange() {
        let range = SpeedRange.portentum8Pro
        #expect(!range.isValid(0.5))
        #expect(!range.isValid(6.5))
        #expect(!range.isValid(-1.0))
    }

    @Test("isValid rejette les pas intermédiaires")
    func invalidOffStep() {
        let range = SpeedRange.portentum8Pro
        #expect(!range.isValid(1.2))
        #expect(!range.isValid(3.33))
    }

    @Test("snap arrondit au pas le plus proche")
    func snapRounding() {
        let range = SpeedRange.portentum8Pro
        #expect(range.snap(1.2) == 1.0)
        #expect(range.snap(1.3) == 1.5)
        #expect(range.snap(3.76) == 4.0)
    }

    @Test("snap clampe aux bornes")
    func snapClamp() {
        let range = SpeedRange.portentum8Pro
        #expect(range.snap(0.0) == 1.0)
        #expect(range.snap(10.0) == 6.0)
    }
}
