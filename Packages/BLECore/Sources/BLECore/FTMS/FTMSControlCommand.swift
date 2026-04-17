// WalkForge — BLECore
// Agent-BLE: encodage des commandes à écrire sur le Control Point (0x2AD9).

import Foundation

/// Commande écrite sur la caractéristique Control Point (`0x2AD9`).
///
/// Chaque cas correspond à un opcode FTMS. L'encodage respecte la spec
/// Bluetooth SIG (little-endian, opérandes signés/non signés selon le cas).
public enum FTMSControlCommand: Sendable, Equatable, Hashable {
    case requestControl
    case reset
    case setTargetSpeed(kmh: Double)
    case setTargetInclination(percent: Double)
    case startOrResume
    case stop
    case pause

    /// Encode en bytes prêts à être écrits sur le Control Point.
    public func encode() -> Data {
        switch self {
        case .requestControl:
            Data([FTMSOpCode.requestControl.rawValue])

        case .reset:
            Data([FTMSOpCode.reset.rawValue])

        case let .setTargetSpeed(kmh):
            Self.encodeSpeed(kmh)

        case let .setTargetInclination(percent):
            Self.encodeInclination(percent)

        case .startOrResume:
            Data([FTMSOpCode.startOrResume.rawValue])

        case .stop:
            Data([FTMSOpCode.stopOrPause.rawValue, FTMSStopOrPauseOperand.stop.rawValue])

        case .pause:
            Data([FTMSOpCode.stopOrPause.rawValue, FTMSStopOrPauseOperand.pause.rawValue])
        }
    }

    /// Opcode FTMS associé à cette commande.
    public var opcode: FTMSOpCode {
        switch self {
        case .requestControl: .requestControl
        case .reset: .reset
        case .setTargetSpeed: .setTargetSpeed
        case .setTargetInclination: .setTargetInclination
        case .startOrResume: .startOrResume
        case .stop, .pause: .stopOrPause
        }
    }

    // MARK: - Encodage privé

    /// Encode `Set Target Speed` (`0x02`) : opcode + uint16 LE (pas de 0.01 km/h).
    private static func encodeSpeed(_ kmh: Double) -> Data {
        let rawInt = Int((kmh * 100).rounded())
        let clamped = UInt16(clamping: rawInt)
        return Data([
            FTMSOpCode.setTargetSpeed.rawValue,
            UInt8(clamped & 0xFF),
            UInt8((clamped >> 8) & 0xFF),
        ])
    }

    /// Encode `Set Target Inclination` (`0x03`) : opcode + int16 LE (pas de 0.1 %).
    private static func encodeInclination(_ percent: Double) -> Data {
        let rawInt = Int((percent * 10).rounded())
        let clamped = Int16(clamping: rawInt)
        let unsigned = UInt16(bitPattern: clamped)
        return Data([
            FTMSOpCode.setTargetInclination.rawValue,
            UInt8(unsigned & 0xFF),
            UInt8((unsigned >> 8) & 0xFF),
        ])
    }
}
