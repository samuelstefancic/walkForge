// WalkForge — BLECoreTests
// Agent-Tests: encodage des commandes Control Point (0x2AD9).
// Vérifié contre la spec Bluetooth SIG FTMS (LE + signed/unsigned).
// swiftlint:disable identifier_name

@testable import BLECore
import Foundation
import Testing

@Suite("FTMSControlCommand · encoding")
struct FTMSControlCommandTests {
    @Test
    func `Request Control (0x00)`() {
        #expect(FTMSControlCommand.requestControl.encode() == Data([0x00]))
    }

    @Test
    func `Reset (0x01)`() {
        #expect(FTMSControlCommand.reset.encode() == Data([0x01]))
    }

    @Test
    func `Start or Resume (0x07)`() {
        #expect(FTMSControlCommand.startOrResume.encode() == Data([0x07]))
    }

    @Test
    func `Stop (0x08 + 0x01)`() {
        #expect(FTMSControlCommand.stop.encode() == Data([0x08, 0x01]))
    }

    @Test
    func `Pause (0x08 + 0x02)`() {
        #expect(FTMSControlCommand.pause.encode() == Data([0x08, 0x02]))
    }

    @Test
    func `Set Target Speed 3.00 km/h → [0x02, 0x2C, 0x01]`() {
        // 3.00 km/h × 100 = 300 = 0x012C → LE [0x2C, 0x01]
        let encoded = FTMSControlCommand.setTargetSpeed(kmh: 3.00).encode()
        #expect(encoded == Data([0x02, 0x2C, 0x01]))
    }

    @Test
    func `Set Target Speed 5.50 km/h → [0x02, 0x26, 0x02]`() {
        // 5.50 × 100 = 550 = 0x0226 → LE [0x26, 0x02]
        let encoded = FTMSControlCommand.setTargetSpeed(kmh: 5.50).encode()
        #expect(encoded == Data([0x02, 0x26, 0x02]))
    }

    @Test
    func `Set Target Speed 1.00 km/h (min PORTENTUM)`() {
        // 1.00 × 100 = 100 = 0x0064
        let encoded = FTMSControlCommand.setTargetSpeed(kmh: 1.00).encode()
        #expect(encoded == Data([0x02, 0x64, 0x00]))
    }

    @Test
    func `Set Target Inclination 2.5% → [0x03, 0x19, 0x00]`() {
        // 2.5 × 10 = 25 = 0x0019
        let encoded = FTMSControlCommand.setTargetInclination(percent: 2.5).encode()
        #expect(encoded == Data([0x03, 0x19, 0x00]))
    }

    @Test
    func `Set Target Inclination 0% → [0x03, 0x00, 0x00]`() {
        let encoded = FTMSControlCommand.setTargetInclination(percent: 0).encode()
        #expect(encoded == Data([0x03, 0x00, 0x00]))
    }

    @Test
    func `Set Target Inclination -1.5% (int16 signé) → [0x03, 0xF1, 0xFF]`() {
        // -1.5 × 10 = -15 → int16 = 0xFFF1 → LE [0xF1, 0xFF]
        let encoded = FTMSControlCommand.setTargetInclination(percent: -1.5).encode()
        #expect(encoded == Data([0x03, 0xF1, 0xFF]))
    }

    @Test
    func `Opcode mapping`() {
        #expect(FTMSControlCommand.requestControl.opcode == .requestControl)
        #expect(FTMSControlCommand.startOrResume.opcode == .startOrResume)
        #expect(FTMSControlCommand.stop.opcode == .stopOrPause)
        #expect(FTMSControlCommand.pause.opcode == .stopOrPause)
        #expect(FTMSControlCommand.setTargetSpeed(kmh: 1).opcode == .setTargetSpeed)
        #expect(FTMSControlCommand.setTargetInclination(percent: 0).opcode == .setTargetInclination)
        #expect(FTMSControlCommand.reset.opcode == .reset)
    }
}
