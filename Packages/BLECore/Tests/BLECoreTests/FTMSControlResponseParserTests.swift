// WalkForge — BLECoreTests
// Agent-Tests: parsing des réponses (opcode 0x80) du Control Point.
// swiftlint:disable identifier_name

@testable import BLECore
import DomainKit
import Foundation
import Testing

@Suite("FTMSControlResponseParser")
struct FTMSControlResponseParserTests {
    @Test
    func `Réponse success pour Request Control`() throws {
        let data = Data([0x80, 0x00, 0x01])
        let response = try FTMSControlResponseParser.parse(data)
        #expect(response.requestOpcode == 0x00)
        #expect(response.resultCode == .success)
    }

    @Test
    func `Réponse Control Not Permitted pour Start`() throws {
        let data = Data([0x80, 0x07, 0x05])
        let response = try FTMSControlResponseParser.parse(data)
        #expect(response.requestOpcode == 0x07)
        #expect(response.resultCode == .controlNotPermitted)
    }

    @Test
    func `Réponse avec opcode inattendu (pas 0x80) → erreur`() {
        let data = Data([0x02, 0x07, 0x01])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSControlResponseParser.parse(data)
        }
    }

    @Test
    func `Réponse trop courte → erreur`() {
        let data = Data([0x80, 0x00])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSControlResponseParser.parse(data)
        }
    }

    @Test
    func `Result code inconnu → erreur`() {
        let data = Data([0x80, 0x00, 0xFF])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSControlResponseParser.parse(data)
        }
    }
}
