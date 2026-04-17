// WalkForge — BLECore
// Agent-BLE: parser binaire de la caractéristique Treadmill Data (0x2ACD).
// Spec : Bluetooth SIG "FTMS Treadmill Data".

import DomainKit
import Foundation

/// Parser de trames `Treadmill Data` (FTMS `0x2ACD`).
///
/// La payload commence par un `flags` (uint16 LE), suivi des champs optionnels
/// dans l'ordre des bits croissants des flags. Chaque champ a une taille et
/// une résolution fixées par la spec Bluetooth SIG.
public enum FTMSTreadmillDataParser {
    /// Décode une trame Treadmill Data en `TreadmillData`.
    ///
    /// - Parameters:
    ///   - data: payload brut reçue du tapis (notification sur `0x2ACD`).
    ///   - timestamp: horodatage à attacher à la lecture (injectable pour tests).
    /// - Returns: un `TreadmillData` renseigné avec tous les champs présents.
    /// - Throws: `TreadmillError.ftmsParseError` si la trame est tronquée
    ///   ou mal formée.
    public static func parse(
        _ data: Data,
        timestamp: Date = Date(),
    ) throws(TreadmillError) -> TreadmillData {
        guard data.count >= 2 else {
            throw .ftmsParseError(reason: "Trame trop courte pour les flags (\(data.count) octets)")
        }

        var cursor = Cursor(data: data, offset: 0)
        let flags = try cursor.readUInt16LE()

        let moreDataBitSet = (flags & FTMSTreadmillDataFlag.moreData.rawValue) != 0
        let has = FlagSet(rawFlags: flags)

        // Bit 0 (More Data) inversé : 0 ⇒ Instantaneous Speed présent.
        let speedKmh: Double = if moreDataBitSet {
            0
        } else {
            try Double(cursor.readUInt16LE()) * 0.01
        }

        if has.averageSpeed {
            _ = try cursor.readUInt16LE()
        }

        let distanceKm: Double = if has.totalDistance {
            try Double(cursor.readUInt24LE()) / 1000.0
        } else {
            0
        }

        var inclinationPercent: Double?
        if has.inclinationAndRampAngle {
            let rawIncline = try cursor.readInt16LE()
            _ = try cursor.readInt16LE() // Ramp Angle ignoré
            inclinationPercent = Double(rawIncline) * 0.1
        }

        if has.elevationGain {
            _ = try cursor.readUInt16LE() // Pos elevation
            _ = try cursor.readUInt16LE() // Neg elevation
        }

        if has.instantaneousPace {
            _ = try cursor.readUInt8()
        }

        if has.averagePace {
            _ = try cursor.readUInt8()
        }

        var totalEnergyKcal: Double?
        if has.expendedEnergy {
            let rawEnergy = try cursor.readUInt16LE()
            _ = try cursor.readUInt16LE() // Energy per hour
            _ = try cursor.readUInt8() // Energy per minute
            // 0xFFFF = "unknown" selon la spec FTMS
            if rawEnergy != 0xFFFF {
                totalEnergyKcal = Double(rawEnergy)
            }
        }

        var heartRate: Int?
        if has.heartRate {
            heartRate = try Int(cursor.readUInt8())
        }

        if has.metabolicEquivalent {
            _ = try cursor.readUInt8()
        }

        var elapsedTimeSeconds = 0
        if has.elapsedTime {
            elapsedTimeSeconds = try Int(cursor.readUInt16LE())
        }

        if has.remainingTime {
            _ = try cursor.readUInt16LE()
        }

        if has.forceOnBeltAndPowerOutput {
            _ = try cursor.readInt16LE() // Force on belt
            _ = try cursor.readInt16LE() // Power output
        }

        return TreadmillData(
            speedKmh: speedKmh,
            distanceKm: distanceKm,
            elapsedTimeSeconds: elapsedTimeSeconds,
            totalEnergyKcal: totalEnergyKcal,
            inclinationPercent: inclinationPercent,
            heartRate: heartRate,
            timestamp: timestamp,
        )
    }

    // MARK: - Helpers internes

    /// Booléens par flag pour améliorer la lisibilité du parsing.
    private struct FlagSet {
        let averageSpeed: Bool
        let totalDistance: Bool
        let inclinationAndRampAngle: Bool
        let elevationGain: Bool
        let instantaneousPace: Bool
        let averagePace: Bool
        let expendedEnergy: Bool
        let heartRate: Bool
        let metabolicEquivalent: Bool
        let elapsedTime: Bool
        let remainingTime: Bool
        let forceOnBeltAndPowerOutput: Bool

        init(rawFlags: UInt16) {
            func isSet(_ flag: FTMSTreadmillDataFlag) -> Bool {
                (rawFlags & flag.rawValue) != 0
            }
            averageSpeed = isSet(.averageSpeed)
            totalDistance = isSet(.totalDistance)
            inclinationAndRampAngle = isSet(.inclinationAndRampAngle)
            elevationGain = isSet(.elevationGain)
            instantaneousPace = isSet(.instantaneousPace)
            averagePace = isSet(.averagePace)
            expendedEnergy = isSet(.expendedEnergy)
            heartRate = isSet(.heartRate)
            metabolicEquivalent = isSet(.metabolicEquivalent)
            elapsedTime = isSet(.elapsedTime)
            remainingTime = isSet(.remainingTime)
            forceOnBeltAndPowerOutput = isSet(.forceOnBeltAndPowerOutput)
        }
    }

    /// Curseur de lecture séquentielle avec bounds checking.
    private struct Cursor {
        let data: Data
        var offset: Int

        mutating func readUInt8() throws(TreadmillError) -> UInt8 {
            try requireBytes(1)
            let byte = data[data.startIndex + offset]
            offset += 1
            return byte
        }

        mutating func readUInt16LE() throws(TreadmillError) -> UInt16 {
            try requireBytes(2)
            let base = data.startIndex + offset
            let value = UInt16(data[base]) | (UInt16(data[base + 1]) << 8)
            offset += 2
            return value
        }

        mutating func readInt16LE() throws(TreadmillError) -> Int16 {
            try Int16(bitPattern: readUInt16LE())
        }

        mutating func readUInt24LE() throws(TreadmillError) -> UInt32 {
            try requireBytes(3)
            let base = data.startIndex + offset
            let value = UInt32(data[base])
                | (UInt32(data[base + 1]) << 8)
                | (UInt32(data[base + 2]) << 16)
            offset += 3
            return value
        }

        private func requireBytes(_ count: Int) throws(TreadmillError) {
            guard offset + count <= data.count else {
                throw .ftmsParseError(
                    reason: "Trame tronquée (besoin de \(count) octets à l'offset \(offset), "
                        + "total \(data.count))",
                )
            }
        }
    }
}
