// WalkForge — BLECoreTests
// Agent-Tests: parsing des réponses (opcode 0x80) du Control Point.

@testable import BLECore
import DomainKit
import Foundation
import Testing

@Suite("FTMSControlResponseParser")
struct FTMSControlResponseParserTests {
    @Test("Réponse success pour Request Control")
    func successResponse() throws {
        let data = Data([0x80, 0x00, 0x01])
        let response = try FTMSControlResponseParser.parse(data)
        #expect(response.requestOpcode == 0x00)
        #expect(response.resultCode == .success)
    }

    @Test("Réponse Control Not Permitted pour Start")
    func controlNotPermitted() throws {
        let data = Data([0x80, 0x07, 0x05])
        let response = try FTMSControlResponseParser.parse(data)
        #expect(response.requestOpcode == 0x07)
        #expect(response.resultCode == .controlNotPermitted)
    }

    @Test("Réponse avec opcode inattendu (pas 0x80)")
    func wrongOpcode() {
        let data = Data([0x02, 0x07, 0x01])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSControlResponseParser.parse(data)
        }
    }

    @Test("Réponse trop courte")
    func tooShort() {
        let data = Data([0x80, 0x00])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSControlResponseParser.parse(data)
        }
    }

    @Test("Result code inconnu")
    func unknownResultCode() {
        let data = Data([0x80, 0x00, 0xFF])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSControlResponseParser.parse(data)
        }
    }
}
