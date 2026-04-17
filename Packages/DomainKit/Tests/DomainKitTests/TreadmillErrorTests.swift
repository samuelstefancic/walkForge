// WalkForge — DomainKitTests
// Agent-Tests: messages d'erreur lisibles par l'utilisateur.

@testable import DomainKit
import Testing

@Suite("TreadmillError")
struct TreadmillErrorTests {
    @Test("Descriptions françaises non vides")
    func descriptions() {
        let cases: [TreadmillError] = [
            .bluetoothUnavailable,
            .bluetoothUnauthorized,
            .bluetoothPoweredOff,
            .deviceNotFound,
            .connectionFailed(reason: "test"),
            .disconnected,
            .controlNotGranted,
            .invalidSpeed(requested: 10, min: 1, max: 6),
            .invalidInclination(requested: 99),
            .ftmsParseError(reason: "test"),
            .ftmsOperationFailed(opcode: 0x02, resultCode: 0x03),
            .notSupported(opcode: 0x05),
            .timeout,
            .notConnected,
        ]
        for error in cases {
            #expect(!error.description.isEmpty)
        }
    }

    @Test("ftmsOperationFailed formate les opcodes en hex")
    func hexFormatting() {
        let error: TreadmillError = .ftmsOperationFailed(opcode: 0x02, resultCode: 0x03)
        #expect(error.description.contains("0x02"))
        #expect(error.description.contains("0x03"))
    }

    @Test("Equatable même cas + paramètres = égaux")
    func equality() {
        let timeoutA: TreadmillError = .timeout
        let timeoutB: TreadmillError = .timeout
        #expect(timeoutA == timeoutB)

        let failA: TreadmillError = .connectionFailed(reason: "a")
        let failA2: TreadmillError = .connectionFailed(reason: "a")
        let failB: TreadmillError = .connectionFailed(reason: "b")
        #expect(failA == failA2)
        #expect(failA != failB)
    }
}
