// WalkForge — BLECoreTests
// Agent-Tests: parsing binaire de trames Treadmill Data (0x2ACD).
// Toutes les trames sont construites conformément à la spec Bluetooth SIG FTMS.

@testable import BLECore
import DomainKit
import Foundation
import Testing

@Suite("FTMSTreadmillDataParser · trames réelles")
struct FTMSTreadmillDataParserTests {
    // MARK: - Cas nominal : speed uniquement (flags = 0x0000)

    @Test("Speed seul : flags=0x0000, speed=3.00 km/h")
    func speedOnly() throws {
        // Payload: flags(2) + speed(2) = 4 octets
        // flags = 0x0000 → bit 0 (More Data) == 0 → speed présente
        // speed raw = 300 = 0x012C → LE [0x2C, 0x01]
        let data = Data([0x00, 0x00, 0x2C, 0x01])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.speedKmh == 3.00)
        #expect(parsed.distanceKm == 0)
        #expect(parsed.elapsedTimeSeconds == 0)
        #expect(parsed.totalEnergyKcal == nil)
        #expect(parsed.inclinationPercent == nil)
        #expect(parsed.heartRate == nil)
    }

    // MARK: - Speed + distance + elapsed

    @Test("Speed + distance + elapsed : flags=0x0404")
    func speedDistanceElapsed() throws {
        // flags bits : 0 (More Data)=0 → speed présente, 2=distance, 10=elapsed
        // flags = 0b0000_0100_0000_0100 = 0x0404 → LE [0x04, 0x04]
        // speed raw = 500 → 5.00 km/h → 0x01F4 LE [0xF4, 0x01]
        // distance raw = 1000 m → 1.00 km → uint24 LE [0xE8, 0x03, 0x00]
        // elapsed raw = 30 s → 0x001E LE [0x1E, 0x00]
        let data = Data([
            0x04, 0x04, // flags
            0xF4, 0x01, // speed = 500 × 0.01 = 5.00
            0xE8, 0x03, 0x00, // distance = 1000 m
            0x1E, 0x00, // elapsed = 30 s
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.speedKmh == 5.00)
        #expect(parsed.distanceKm == 1.00)
        #expect(parsed.elapsedTimeSeconds == 30)
    }

    // MARK: - Inclinaison

    @Test("Inclinaison positive 2.5%")
    func inclinationPositive() throws {
        // flags = 0x0008 (bit 3 = inclination)
        // speed = 0.00 (mais bit 0 = 0 donc speed présente = 2 bytes à 0)
        // inclination raw = 25 (0x0019) → 2.5 %
        // ramp angle = 0 (ignoré)
        let data = Data([
            0x08, 0x00, // flags = 0x0008
            0x00, 0x00, // speed = 0
            0x19, 0x00, // inclination = 25 → 2.5 %
            0x00, 0x00, // ramp angle = 0
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.inclinationPercent == 2.5)
    }

    @Test("Inclinaison négative -1.5% (int16 signé)")
    func inclinationNegative() throws {
        // int16 -15 = 0xFFF1 LE [0xF1, 0xFF]
        let data = Data([
            0x08, 0x00,
            0x00, 0x00,
            0xF1, 0xFF, // inclination = -15 → -1.5 %
            0x00, 0x00,
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.inclinationPercent == -1.5)
    }

    // MARK: - Énergie

    @Test("Énergie présente : total = 42 kcal")
    func totalEnergy() throws {
        // flags = 0x0080 (bit 7 expended energy)
        // total = 42 kcal = 0x002A LE [0x2A, 0x00]
        // energy per hour = 0, per minute = 0
        let data = Data([
            0x80, 0x00,
            0x00, 0x00, // speed
            0x2A, 0x00, // total kcal = 42
            0x00, 0x00, // energy per hour
            0x00, // energy per minute
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.totalEnergyKcal == 42.0)
    }

    @Test("Énergie 0xFFFF = inconnu → nil")
    func energyUnknownSentinel() throws {
        let data = Data([
            0x80, 0x00,
            0x00, 0x00,
            0xFF, 0xFF, // 0xFFFF = unknown selon FTMS
            0x00, 0x00,
            0x00,
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.totalEnergyKcal == nil)
    }

    // MARK: - Fréquence cardiaque

    @Test("Heart Rate 120 bpm (flags=0x0100)")
    func heartRate() throws {
        let data = Data([
            0x00, 0x01, // flags = 0x0100 (bit 8 heart rate)
            0x00, 0x00, // speed
            0x78, // HR = 120
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.heartRate == 120)
    }

    // MARK: - Combinaison complète

    @Test("Trame complète : speed + distance + incline + energy + HR + elapsed")
    func fullFrame() throws {
        // flags bits : 2 (distance), 3 (incline), 7 (energy), 8 (HR), 10 (elapsed)
        // = 0b0000_0101_1000_1100 = 0x058C
        let data = Data([
            0x8C, 0x05, // flags
            0x2C, 0x01, // speed = 300 → 3.00
            0xE8, 0x03, 0x00, // distance = 1000 m = 1.0 km
            0x19, 0x00, // incline = 25 → 2.5 %
            0x00, 0x00, // ramp angle
            0x2A, 0x00, // total kcal = 42
            0x00, 0x00, // energy/hour
            0x00, // energy/minute
            0x78, // HR = 120
            0x3C, 0x00, // elapsed = 60
        ])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.speedKmh == 3.00)
        #expect(parsed.distanceKm == 1.00)
        #expect(parsed.inclinationPercent == 2.5)
        #expect(parsed.totalEnergyKcal == 42.0)
        #expect(parsed.heartRate == 120)
        #expect(parsed.elapsedTimeSeconds == 60)
    }

    // MARK: - More Data bit : speed absente

    @Test("Bit More Data = 1 → speed = 0")
    func moreDataBitSet() throws {
        // flags = 0x0001 : bit 0 = 1 → Instantaneous Speed ABSENTE
        let data = Data([0x01, 0x00])
        let parsed = try FTMSTreadmillDataParser.parse(data)

        #expect(parsed.speedKmh == 0)
    }

    // MARK: - Robustesse — trames malformées

    @Test("Trame vide → erreur")
    func emptyData() {
        #expect(throws: TreadmillError.self) {
            _ = try FTMSTreadmillDataParser.parse(Data())
        }
    }

    @Test("Trame avec flags seulement, speed présente mais tronquée")
    func truncatedSpeed() {
        // flags = 0x0000 implique speed présente (2 bytes), mais on coupe avant
        let data = Data([0x00, 0x00, 0x2C]) // 1 byte pour speed au lieu de 2
        #expect(throws: TreadmillError.self) {
            _ = try FTMSTreadmillDataParser.parse(data)
        }
    }

    @Test("Trame distance tronquée (2 bytes au lieu de 3)")
    func truncatedDistance() {
        // flags = 0x0004 (distance), speed + 2 bytes au lieu de 3
        let data = Data([
            0x04, 0x00,
            0x00, 0x00,
            0x01, 0x02, // distance coupée
        ])
        #expect(throws: TreadmillError.self) {
            _ = try FTMSTreadmillDataParser.parse(data)
        }
    }
}
